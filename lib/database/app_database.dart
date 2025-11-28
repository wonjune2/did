import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()(); // 자동 증가 ID
  TextColumn get title => text()(); // 할 일 제목
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))(); // 완료 여부
  DateTimeColumn get createdAt => dateTime()(); // 생성 시간
  DateTimeColumn get completeAt => dateTime().nullable()(); // 완료 시간

  IntColumn get projectId => integer().nullable().references(Projects, #id)();
}

class TaskWithProject {
  final Task task;
  final Project? project;

  TaskWithProject({required this.task, this.project});
}

@DriftDatabase(tables: [Tasks, Projects])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // 마이그레이션 로직 (기존 앱 사용자를 위해 필요하지만, 개발 중엔 DB파일 삭제 추천)
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // 버전 2로 올 때 Projects 테이블 생성 및 Tasks에 컬럼 추가
          await m.createTable(projects);
          await m.addColumn(tasks, tasks.projectId);
        }
      },
    );
  }

  // -- 프로젝트 관련 쿼리 --

  // 모든 프로젝트 가져오기
  Stream<List<Project>> watchAllProjects() {
    return select(projects).watch();
  }

  // 프로젝트 추가
  Future<int> insertProject(String name) {
    return into(projects).insert(ProjectsCompanion.insert(name: name));
  }

  // 프로젝트 삭제 (관련 업무의 projectId를 null로 변경할지, 삭제할지 결정 필요. 여기선 간단히 프로젝트만 삭제)
  Future<int> deleteProject(int id) {
    return (delete(projects)..where((p) => p.id.equals(id))).go();
  }

  // -- 업무 쿼리 메서드들 (Service 역할) --

  // 모든 업무 실시간 감지 (최신순 정렬)
  Stream<List<TaskWithProject>> watchAllTasksWithProjects() {
    final query = select(
      tasks,
    ).join([leftOuterJoin(projects, projects.id.equalsExp(tasks.projectId))]);

    // 최신순 정렬
    query.orderBy([OrderingTerm(expression: tasks.createdAt, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithProject(task: row.readTable(tasks), project: row.readTableOrNull(projects));
      }).toList();
    });
  }

  // 업무 추가
  Future<int> insertTask(String title, {int? projectId}) {
    return into(tasks).insert(
      TasksCompanion.insert(title: title, createdAt: DateTime.now(), projectId: Value(projectId)),
    );
  }

  // 완료 상태 토글
  Future<void> toggleTask(Task task) {
    final newStatus = !task.isCompleted;
    return update(tasks).replace(
      task.copyWith(isCompleted: newStatus, completeAt: Value(newStatus ? DateTime.now() : null)),
    );
  }

  // 업무 삭제
  Future<int> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  // 주간보고: 기간별 완료 업무 조회 (주간 보고)
  Stream<List<Task>> watchCompletedTasksByDate(DateTime start, DateTime end) {
    // start는 00:00:00, end는 23:59:59로 설정
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = select(
      tasks,
    ).join([leftOuterJoin(projects, projects.id.equalsExp(tasks.projectId))]);

    query.where(
      tasks.isCompleted.equals(true) & tasks.completeAt.isBetweenValues(startDate, endDate),
    );

    query.orderBy([OrderingTerm(expression: tasks.completeAt)]);

    return (select(tasks)
          ..where(
            (t) => t.isCompleted.equals(true) & t.completeAt.isBetweenValues(startDate, endDate),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.completeAt)]))
        .watch();
  }

  // 하스토리용: 완료된 업무만 최신순으로 실시간 감지
  Stream<List<TaskWithProject>> watchCompletedTasksWithProjects() {
    final query = select(
      tasks,
    ).join([leftOuterJoin(projects, projects.id.equalsExp(tasks.projectId))]);

    // 완료된 것만 필터링
    query.where(tasks.isCompleted.equals(true));

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithProject(task: row.readTable(tasks), project: row.readTableOrNull(projects));
      }).toList();
    });
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
