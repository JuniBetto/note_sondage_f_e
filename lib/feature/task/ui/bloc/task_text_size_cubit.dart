import 'package:bloc/bloc.dart';
import 'package:note_sondage/feature/task/domain/entities/task_text_size.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _taskTextSizePrefKey = 'task_text_size';

/// Persists the user's preferred text size (small/medium/large) for the Task
/// feature's mobile/compact views, so the whole UI can be scaled to show
/// more content in less space.
class TaskTextSizeCubit extends Cubit<TaskTextSize> {
  TaskTextSizeCubit() : super(TaskTextSize.medium);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    emit(TaskTextSizeWireValue.fromWireValue(prefs.getString(_taskTextSizePrefKey)));
  }

  Future<void> setSize(TaskTextSize size) async {
    if (size == state) {
      return;
    }
    emit(size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_taskTextSizePrefKey, size.wireValue);
  }
}
