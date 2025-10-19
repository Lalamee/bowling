import 'package:flutter/foundation.dart';

class TestOverrides {
  static const forceFirstRun = bool.fromEnvironment('FORCE_FIRST_RUN', defaultValue: false);
  static const forceSecondRun = bool.fromEnvironment('FORCE_SECOND_RUN', defaultValue: false);
  static const userRole = String.fromEnvironment('USER_ROLE', defaultValue: 'mechanic');
  static const useLoginScreen = bool.fromEnvironment('USE_LOGIN_SCREEN', defaultValue: false);
  static bool get enabled => kDebugMode && (forceFirstRun || forceSecondRun);
}
