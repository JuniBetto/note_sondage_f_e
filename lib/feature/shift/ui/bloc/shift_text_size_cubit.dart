import 'package:bloc/bloc.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_text_size.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _shiftTextSizePrefKey = 'shift_text_size';

/// Persists the user's preferred text size (small/medium/large) for the
/// Shift feature's mobile/compact views, so the whole UI can be scaled to
/// show more content in less space.
class ShiftTextSizeCubit extends Cubit<ShiftTextSize> {
  ShiftTextSizeCubit() : super(ShiftTextSize.medium);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    emit(
      ShiftTextSizeWireValue.fromWireValue(
        prefs.getString(_shiftTextSizePrefKey),
      ),
    );
  }

  Future<void> setSize(ShiftTextSize size) async {
    if (size == state) {
      return;
    }
    emit(size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shiftTextSizePrefKey, size.wireValue);
  }
}
