import 'package:flutter_test/flutter_test.dart';
import 'package:note_sondage/core/config/runtime_config.dart';

void main() {
  tearDown(() {
    RuntimeConfig.debugSetEnableWorkflowActionsOverride(null);
  });

  group('RuntimeConfig.enableWorkflowActions', () {
    test('can be forced off for tests', () {
      RuntimeConfig.debugSetEnableWorkflowActionsOverride(false);

      expect(RuntimeConfig.enableWorkflowActions, isFalse);
    });

    test('can be forced on for tests', () {
      RuntimeConfig.debugSetEnableWorkflowActionsOverride(false);
      RuntimeConfig.debugSetEnableWorkflowActionsOverride(true);

      expect(RuntimeConfig.enableWorkflowActions, isTrue);
    });

    test('returns to default behavior when override is cleared', () {
      RuntimeConfig.debugSetEnableWorkflowActionsOverride(false);
      RuntimeConfig.debugSetEnableWorkflowActionsOverride(null);

      expect(RuntimeConfig.enableWorkflowActions, isTrue);
    });
  });
}
