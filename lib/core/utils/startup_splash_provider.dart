import 'package:flutter_riverpod/flutter_riverpod.dart';

final startupSplashDelayProvider = FutureProvider<void>((ref) async {
  await Future<void>.delayed(const Duration(seconds: 2));
});
