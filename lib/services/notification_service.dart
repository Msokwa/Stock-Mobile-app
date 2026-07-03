import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'notifications';

  /// Creates a notification for the specified user.
  static Future<void> createNotification({
    required String userId,
    required String title,
    String? message,
    String? type,
  }) async {
    await _supabase.from(_table).insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
    });
  }

  /// Creates a notification for the currently authenticated user.
  static Future<void> createNotificationForCurrentUser({
    required String title,
    String? message,
    String? type,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    await createNotification(
      userId: user.id,
      title: title,
      message: message,
      type: type,
    );
  }

  /// Fetches notifications for the specified user.
  static Future<List<Map<String, dynamic>>> fetchNotifications(
    String userId,
  ) async {
    final data = await _supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Streams realtime notifications for the specified user.
  static Stream<List<Map<String, dynamic>>> streamNotifications(
    String userId,
  ) {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => (data as List<dynamic>).cast<Map<String, dynamic>>());
  }

  /// Deletes a notification by its primary key.
  static Future<void> deleteNotification(String id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }
}
