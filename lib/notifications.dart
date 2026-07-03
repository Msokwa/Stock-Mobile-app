import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stock_app/services/notification_service.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final List<Map<String, dynamic>> _notifications = [];
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscribeNotifications();
  }

  Future<void> _subscribeNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'No user signed in.';
        _loading = false;
      });
      return;
    }

    try {
      final initialData = await NotificationService.fetchNotifications(user.id);
      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(initialData);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }

    _subscription = NotificationService.streamNotifications(user.id).listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _notifications
            ..clear()
            ..addAll(data);
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _error = error.toString();
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _formatCreatedAt(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'Just now';
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    } catch (_) {
      return createdAt;
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Widget _buildNotificationTile(Map<String, dynamic> item) {
    final title =
        item['title']?.toString() ?? item['type']?.toString() ?? 'Notification';
    final message =
        item['message']?.toString() ??
        item['body']?.toString() ??
        'No details available';
    final createdAt = _formatCreatedAt(item['created_at']?.toString());
    final type = (item['type'] as String?)?.toLowerCase() ?? '';
    final icon = type.contains('alert')
        ? Icons.notifications_active_rounded
        : Icons.notifications_none_rounded;
    final iconColor = type.contains('alert') ? Colors.red : Colors.greenAccent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF091625),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            createdAt,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF091625),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            : _notifications.isEmpty
            ? const Center(
                child: Text(
                  'No notifications yet.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await _subscribeNotifications();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) =>
                      _buildNotificationTile(_notifications[index]),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: _notifications.length,
                ),
              ),
      ),
    );
  }
}
