import 'package:shared_preferences/shared_preferences.dart';

class LastSeenService {
  const LastSeenService._();

  static const feedKey = 'last_seen_feed_at';
  static const eventsKey = 'last_seen_events_at';

  static Future<DateTime?> getLastSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(key);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<void> setLastSeen(String key, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value.millisecondsSinceEpoch);
  }
}
