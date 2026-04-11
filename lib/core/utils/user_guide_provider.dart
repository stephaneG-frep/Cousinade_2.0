import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userGuideProvider =
    StateNotifierProvider<UserGuideController, UserGuideState>(
      (ref) => UserGuideController()..load(),
    );

class UserGuideState {
  const UserGuideState({required this.isLoaded, required this.hasSeenGuide});

  final bool isLoaded;
  final bool hasSeenGuide;

  UserGuideState copyWith({bool? isLoaded, bool? hasSeenGuide}) {
    return UserGuideState(
      isLoaded: isLoaded ?? this.isLoaded,
      hasSeenGuide: hasSeenGuide ?? this.hasSeenGuide,
    );
  }
}

class UserGuideController extends StateNotifier<UserGuideState> {
  UserGuideController()
    : super(const UserGuideState(isLoaded: false, hasSeenGuide: false));

  static const _hasSeenGuideKey = 'has_seen_user_guide';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenGuide = prefs.getBool(_hasSeenGuideKey) ?? false;
    state = UserGuideState(isLoaded: true, hasSeenGuide: hasSeenGuide);
  }

  Future<void> markGuideSeen() async {
    state = state.copyWith(hasSeenGuide: true, isLoaded: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenGuideKey, true);
  }

  Future<void> markGuideUnseen() async {
    state = state.copyWith(hasSeenGuide: false, isLoaded: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenGuideKey, false);
  }
}
