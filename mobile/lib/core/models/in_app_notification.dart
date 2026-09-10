class InAppNotificationItem {
  final String id;
  final String conversationId;
  final String conversationName;
  final String senderName;
  final String? senderAvatar;
  final String previewText;
  final String messageType;
  final DateTime timestamp;

  InAppNotificationItem({
    required this.id,
    required this.conversationId,
    required this.conversationName,
    required this.senderName,
    this.senderAvatar,
    required this.previewText,
    this.messageType = 'TEXT',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory InAppNotificationItem.fromSocketData(Map<String, dynamic> data) {
    final message = (data['message'] as Map<String, dynamic>?) ?? data;
    final sender = (message['sender'] as Map<String, dynamic>?) ?? {};
    
    final senderName = (sender['name'] as String?)?.isNotEmpty == true 
        ? sender['name'] as String 
        : (sender['username'] as String?) ?? 'New Message';
    final senderAvatar = sender['avatarUrl'] as String?;
    
    final type = (message['type'] as String?) ?? 'TEXT';
    String preview = message['content'] as String? ?? '';

    if (type == 'IMAGE') {
      preview = '📷 Sent a photo';
    } else if (type == 'VOICE') {
      preview = '🎤 Sent a voice message';
    } else if (type == 'LOCATION' || type == 'LIVE_LOCATION') {
      preview = '📍 Shared location';
    } else if (type == 'DOCUMENT') {
      preview = '📎 Sent a document';
    } else if (type == 'TASK') {
      preview = '📋 Assigned a task';
    } else if (type == 'PAYMENT') {
      preview = '💳 Sent an invoice';
    } else if (type == 'POLL') {
      preview = '📊 Created a poll';
    } else if (preview.isEmpty) {
      preview = 'Sent a new message';
    }

    return InAppNotificationItem(
      id: (message['id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: (data['conversationId'] as String?) ?? (message['conversationId'] as String?) ?? '',
      conversationName: senderName,
      senderName: senderName,
      senderAvatar: senderAvatar,
      previewText: preview,
      messageType: type,
      timestamp: DateTime.now(),
    );
  }
}
