import 'package:bloc/bloc.dart';
import 'package:note_sondage/feature/event/domain/entities/event_text_size.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _eventTextSizePrefKey = 'event_text_size';

/// Persists the user's preferred text size (small/medium/large) for the
/// Event feature's mobile/compact views, so the whole UI can be scaled to
/// show more content in less space.
class EventTextSizeCubit extends Cubit<EventTextSize> {
  EventTextSizeCubit() : super(EventTextSize.medium);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    emit(
      EventTextSizeWireValue.fromWireValue(
        prefs.getString(_eventTextSizePrefKey),
      ),
    );
  }

  Future<void> setSize(EventTextSize size) async {
    if (size == state) {
      return;
    }
    emit(size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eventTextSizePrefKey, size.wireValue);
  }
}
