part of 'task_bloc.dart';

abstract class TaskState {
  const TaskState();
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskCreated extends TaskState {
  const TaskCreated(this.task);

  final TaskEntity task;
}

class TaskUpdated extends TaskState {
  const TaskUpdated(this.task);

  final TaskEntity task;
}

class TaskArchived extends TaskState {
  const TaskArchived(this.task);

  final TaskEntity task;
}

class TaskDeleted extends TaskState {
  const TaskDeleted(this.task);

  final TaskEntity task;
}
