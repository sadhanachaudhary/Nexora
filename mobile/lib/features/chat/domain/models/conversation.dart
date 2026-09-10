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
  final int unreadCount;

  Conversation({
    required this.id,
    required this.isGroup,
    this.name,
    this.imageUrl,
    required this.members,
    this.latestMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  Conversation copyWith({
    String? id,
    bool? isGroup,
    String? name,
    String? imageUrl,
    List<ConversationMember>? members,
    Message? latestMessage,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      isGroup: isGroup ?? this.isGroup,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      members: members ?? this.members,
      latestMessage: latestMessage ?? this.latestMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

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
      unreadCount: (json['unreadCount'] as int?) ?? 0,
    );
  }

  String getDisplayName(String currentUserId) {
    if (isGroup && name != null && name!.isNotEmpty) return name!;
    if (members.isEmpty) return name ?? 'Chat';
    
    // For direct chats, find the other user's name
    for (final member in members) {
      if (member.user.id != currentUserId) {
        return member.user.name ?? member.user.username;
      }
    }
    return members.first.user.name ?? members.first.user.username;
  }

  String? getDisplayAvatarUrl(String currentUserId) {
    if (isGroup) return imageUrl;
    if (members.isEmpty) return null;
    
    for (final member in members) {
      if (member.user.id != currentUserId) {
        return member.user.avatarUrl;
      }
    }
    return members.first.user.avatarUrl;
  }
}
