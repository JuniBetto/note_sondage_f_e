import 'package:bloc/bloc.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_status.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/domain/use_case/task_use_case.dart';

part 'task_state.dart';

/// Sottile wrapper attorno a [TaskUseCase] che emette uno stato ad ogni
/// mutazione riuscita, cosi che [TaskAlarmScheduler] possa osservarle e
/// schedulare/cancellare i promemoria locali — lo stesso ruolo che [ShiftBloc]
/// gioca per [ShiftAlarmScheduler].
///
/// Gli errori non vengono catturati qui: si propagano al chiamante esattamente
/// come con [TaskUseCase], cosi da non alterare la logica di
/// optimistic-update/rollback gia presente in `task_workspace.dart`.
class TaskBloc extends Cubit<TaskState> {
  TaskBloc(this._useCase) : super(const TaskInitial());

  final TaskUseCase _useCase;

  Future<TaskEntity> createTask(TaskCreateRequestEntity request) async {
    final task = await _useCase.createTask(request);
    emit(TaskCreated(task));
    return task;
  }

  Future<TaskEntity> updateTask(
    String taskId,
    TaskUpdateRequestEntity request,
  ) async {
    final task = await _useCase.updateTask(taskId, request);
    emit(TaskUpdated(task));
    return task;
  }

  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status) async {
    final task = await _useCase.updateTaskStatus(taskId, status);
    emit(TaskUpdated(task));
    return task;
  }

  Future<TaskEntity> archiveTask(String taskId) async {
    final task = await _useCase.archiveTask(taskId);
    emit(TaskArchived(task));
    return task;
  }

  Future<TaskEntity> unarchiveTask(String taskId) async {
    final task = await _useCase.unarchiveTask(taskId);
    emit(TaskUpdated(task));
    return task;
  }

  Future<void> deleteTaskPermanently(TaskEntity task) async {
    await _useCase.deleteTaskPermanently(task.id);
    emit(TaskDeleted(task));
  }
}
