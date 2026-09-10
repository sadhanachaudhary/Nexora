import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;
  final FlutterSecureStorage _storage;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  final _reactionController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get reactionStream => _reactionController.stream;

  final _deleteController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get deleteStream => _deleteController.stream;

  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get readStream => _readController.stream;

  SocketService(this._storage);

  Future<void> connect() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    _socket = IO.io(
      'http://127.0.0.1:3001',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      print('Connected to Socket.io server');
    });

    _socket?.on('receiveMessage', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('typing', (data) {
      if (data is Map<String, dynamic>) {
        _typingController.add(data);
      } else if (data is Map) {
        _typingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('messageReaction', (data) {
      if (data is Map<String, dynamic>) {
        _reactionController.add(data);
      } else if (data is Map) {
        _reactionController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('messageDeleted', (data) {
      if (data is Map<String, dynamic>) {
        _deleteController.add(data);
      } else if (data is Map) {
        _deleteController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('messagesRead', (data) {
      if (data is Map<String, dynamic>) {
        _readController.add(data);
      } else if (data is Map) {
        _readController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.onDisconnect((_) {
      print('Disconnected from Socket.io server');
    });
  }

  void joinRoom(String conversationId) {
    _socket?.emit('joinRoom', conversationId);
  }

  void leaveRoom(String conversationId) {
    _socket?.emit('leaveRoom', conversationId);
  }

  void sendMessage({
    required String conversationId,
    required String content,
    String type = 'TEXT',
    String? replyToId,
  }) {
    _socket?.emit('sendMessage', {
      'conversationId': conversationId,
      'content': content,
      'type': type,
      if (replyToId != null) 'replyToId': replyToId,
    });
  }

  void sendReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) {
    _socket?.emit('reaction', {
      'conversationId': conversationId,
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  void sendDeleteMessage({
    required String conversationId,
    required String messageId,
  }) {
    _socket?.emit('deleteMessage', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  void sendMarkRead(String conversationId) {
    _socket?.emit('markRead', {
      'conversationId': conversationId,
    });
  }

  void sendImageMessage({
    required String conversationId,
    required String attachmentUrl,
  }) {
    _socket?.emit('sendMessage', {
      'conversationId': conversationId,
      'type': 'IMAGE',
      'attachmentUrl': attachmentUrl,
    });
  }

  void sendTyping(String conversationId, bool isTyping) {
    _socket?.emit('typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void disconnect() {
    _socket?.disconnect();
  }
}
