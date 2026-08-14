part of 'my_tasks_cubit.dart';

class MyTask {
  const MyTask({
    required this.teamNumber,
    required this.nickname,
    required this.done,
  });

  final int teamNumber;
  final String nickname;
  final bool done;
}

sealed class MyTasksState {
  const MyTasksState();
}

class MyTasksEmpty extends MyTasksState {
  const MyTasksEmpty();
}

class MyTasksLoaded extends MyTasksState {
  const MyTasksLoaded({required this.eventKey, required this.tasks});

  final String eventKey;
  final List<MyTask> tasks;

  int get doneCount => tasks.where((t) => t.done).length;
  int get remainingCount => tasks.length - doneCount;
  bool get allDone => tasks.isNotEmpty && remainingCount == 0;
}
