import 'user.dart';
import 'message.dart';

class ConversationMember {
  final User user;
  final String role;

  ConversationMember({required this.user, required this.role});

  factory ConversationMember.fromJson(Map<String, dynamic> json) {
    return ConversationMember(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      role: json['role'] as String,
    );
  }
}

class Conversation {
  final String id;
  final bool isGroup;
  final String? name;
  final String? imageUrl;
  final List<ConversationMember> members;
  final Message? latestMessage;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.isGroup,
    this.name,
    this.imageUrl,
    required this.members,
    this.latestMessage,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    Message? latestMsg;
    if (json['messages'] != null && (json['messages'] as List).isNotEmpty) {
      latestMsg = Message.fromJson((json['messages'] as List).first as Map<String, dynamic>);
    }

    return Conversation(
      id: json['id'] as String,
      isGroup: json['isGroup'] as bool,
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      members: (json['members'] as List)
          .map((m) => ConversationMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      latestMessage: latestMsg,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String getDisplayName(String currentUserId) {
    if (isGroup && name != null) return name!;
    
    // For direct chats, find the other user's name
    final otherMember = members.firstWhere(
      (m) => m.user.id != currentUserId,
      orElse: () => members.first,
    );
    return otherMember.user.name ?? otherMember.user.username;
  }
}
