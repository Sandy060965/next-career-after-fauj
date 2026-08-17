import 'dart:async';
import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => Directory.systemTemp.path;
}

/// Runs once for the whole test suite. Without these mocks,
/// ProfileRepository's SharedPreferences/path_provider calls hang or fail
/// waiting for platform channels that don't exist in the test environment
/// (no real device), which times out pumpAndSettle rather than failing
/// fast.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  SharedPreferences.setMockInitialValues({});
  PathProviderPlatform.instance = _FakePathProviderPlatform();
  await testMain();
}
