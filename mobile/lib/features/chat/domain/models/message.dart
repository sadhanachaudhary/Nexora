import 'user.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String type;
  final String? attachmentUrl;
  final String? replyToId;
  final String status;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final User? sender;
  final Map<String, List<String>> reactions; // emoji -> list of userIds
  final bool isEdited;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    required this.type,
    this.attachmentUrl,
    this.replyToId,
    required this.status,
    required this.createdAt,
    this.deletedAt,
    this.sender,
    this.reactions = const {},
    this.isEdited = false,
  });

  bool get isDeleted => deletedAt != null;

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? type,
    String? attachmentUrl,
    String? replyToId,
    String? status,
    DateTime? createdAt,
    DateTime? deletedAt,
    User? sender,
    Map<String, List<String>>? reactions,
    bool? isEdited,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      replyToId: replyToId ?? this.replyToId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      sender: sender ?? this.sender,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> parsedReactions = {};
    if (json['reactions'] != null && json['reactions'] is Map) {
      (json['reactions'] as Map).forEach((key, val) {
        if (val is List) {
          parsedReactions[key.toString()] = val.map((e) => e.toString()).toList();
        }
      });
    }

    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String?,
      type: (json['type'] as String?) ?? 'TEXT',
      attachmentUrl: json['attachmentUrl'] as String?,
      replyToId: json['replyToId'] as String?,
      status: (json['status'] as String?) ?? 'SENT',
      createdAt: DateTime.parse(json['createdAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
      sender: json['sender'] != null
          ? User.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      reactions: parsedReactions,
      isEdited: (json['isEdited'] as bool?) ?? false,
    );
  }
}
