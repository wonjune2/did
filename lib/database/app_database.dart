import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()(); // 자동 증가 ID
  TextColumn get title => text()(); // 할 일 제목
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))(); // 완료 여부
  DateTimeColumn get createdAt => dateTime()(); // 생성 시간
  DateTimeColumn get completeAt => dateTime().nullable()(); // 완료 시간
}

@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // -- 쿼리 메서드들 (Service 역할) --

  // 모든 업무 실시간 감지 (최신순 정렬)
  Stream<List<Task>> watchAllTasks() {
    return (select(tasks)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  // 업무 추가
  Future<int> insertTask(String title) {
    return into(
      tasks,
    ).insert(TasksCompanion.insert(title: title, createdAt: DateTime.now()));
  }

  // 완료 상태 토글
  Future<void> toggleTask(Task task) {
    final newStatus = !task.isCompleted;
    return update(tasks).replace(
      task.copyWith(
        isCompleted: newStatus,
        completeAt: Value(newStatus ? DateTime.now() : null),
      ),
    );
  }

  // 업무 삭제
  Future<int> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  // 기간별 완료 업무 조회 (주간 보고)
  Future<List<Task>> getCompletedTasksByDate(DateTime start, DateTime end) {
    // start는 00:00:00, end는 23:59:59로 설정
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return (select(tasks)
          ..where(
            (t) =>
                t.isCompleted.equals(true) &
                t.completeAt.isBetweenValues(startDate, endDate),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.completeAt)]))
        .get();
  }

  // DB 파일 연결 설정 (윈도우/맥/모바일 공용)
  // 연결 함수 교체 (이게 최신 방식입니다)
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      return driftDatabase(
        name: 'did_db', // 파일 이름만 정해주면 경로 등은 알아서 해줌
        native: const DriftNativeOptions(
          shareAcrossIsolates: true, // 백그라운드 작업 지원
        ),
      );
    });
  }
}
