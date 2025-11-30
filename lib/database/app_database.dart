import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()(); // 자동 증가 ID
  TextColumn get title => text()(); // 할 일 제목
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))(); // 완료 여부
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
  int get schemaVersion => 3;

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
        if (from < 3) {
          // 버전 3으로 올 때 Projects 테이블에 isActive 컬럼 추가
          await m.addColumn(projects, projects.isActive);

          // 기존 데이터의 isActive를 true로 설정
          await (update(
            projects,
          )).write(const ProjectsCompanion(isActive: Value(true)));
        }
      },
    );
  }

  // -- 프로젝트 관련 쿼리 --

  // 모든 프로젝트 가져오기 (활성화된 것만)
  Stream<List<Project>> watchAllProjects() {
    return (select(projects)..where((p) => p.isActive.equals(true))).watch();
  }

  // 모든 프로젝트 가져오기 (비활성화 포함 - 설정 화면용)
  Stream<List<Project>> watchAllProjectsIncludingInactive() {
    return select(projects).watch();
  }

  // 프로젝트 추가
  Future<int> insertProject(String name) {
    return into(projects).insert(ProjectsCompanion.insert(name: name));
  }

  // 프로젝트 삭제 (비활성화 처리)
  Future<void> deleteProject(int id) {
    return (update(projects)..where((p) => p.id.equals(id))).write(
      const ProjectsCompanion(isActive: Value(false)),
    );
  }

  // -- 업무 쿼리 메서드들 (Service 역할) --

  // [New] '오늘 할 일' 탭용: 완료 안 된 것만 가져오기 + 프로젝트 정보
  Stream<List<TaskWithProject>> watchIncompleteTasksWithProject() {
    final query = select(
      tasks,
    ).join([leftOuterJoin(projects, projects.id.equalsExp(tasks.projectId))]);

    // 🔥 핵심: 완료되지 않은 것(false)만 필터링
    query.where(tasks.isCompleted.equals(false));

    // 최신순 정렬
    query.orderBy([
      OrderingTerm(expression: tasks.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithProject(
          task: row.readTable(tasks),
          project: row.readTableOrNull(projects),
        );
      }).toList();
    });
  }

  // 모든 업무 실시간 감지 (최신순 정렬)
  Stream<List<TaskWithProject>> watchAllTasksWithProjects() {
    final query = select(
      tasks,
    ).join([leftOuterJoin(projects, projects.id.equalsExp(tasks.projectId))]);

    // 최신순 정렬
    query.orderBy([
      OrderingTerm(expression: tasks.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithProject(
          task: row.readTable(tasks),
          project: row.readTableOrNull(projects),
        );
      }).toList();
    });
  }

  // 업무 추가
  Future<int> insertTask(String title, {int? projectId}) {
    return into(tasks).insert(
      TasksCompanion.insert(
        title: title,
        createdAt: DateTime.now(),
        projectId: Value(projectId),
      ),
    );
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

  // 2. [Report용] 기간별 완료 업무 + 프로젝트 정보
  Stream<List<TaskWithProject>> watchCompletedTasksWithProjectByDate(
    DateTime start,
    DateTime end,
  ) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = select(
      tasks,
    ).join([leftOuterJoin(projects, projects.id.equalsExp(tasks.projectId))]);

    query.where(
      tasks.isCompleted.equals(true) &
          tasks.completeAt.isBetweenValues(startDate, endDate),
    );

    // 정렬: 완료일 순서
    query.orderBy([OrderingTerm(expression: tasks.completeAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithProject(
          task: row.readTable(tasks),
          project: row.readTableOrNull(projects),
        );
      }).toList();
    });
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
        return TaskWithProject(
          task: row.readTable(tasks),
          project: row.readTableOrNull(projects),
        );
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
