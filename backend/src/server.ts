import http from 'http';
import { Server } from 'socket.io';
import app from './app';
import jwt from 'jsonwebtoken';
import { MessageService } from './services/message.service';
import { PrismaClient } from '@prisma/client';

const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'super-secret-key-for-dev';

const prisma = new PrismaClient();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const messageService = new MessageService();

// Middleware to authenticate socket connections
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) {
    return next(new Error('Authentication error: Token missing'));
  }

  jwt.verify(token, JWT_SECRET, (err: any, decoded: any) => {
    if (err) {
      return next(new Error('Authentication error: Invalid token'));
    }
    socket.data.user = decoded;
    next();
  });
});

io.on('connection', (socket) => {
  const userId = socket.data.user?.id;
  console.log(`User connected: ${userId}`);

  // Automatically join personal user room for direct notifications
  if (userId) {
    socket.join(`user:${userId}`);
    console.log(`User ${userId} joined room user:${userId}`);
  }

  // Join a room (conversation)
  socket.on('joinRoom', (conversationId) => {
    socket.join(conversationId);
    console.log(`User ${socket.data.user.id} joined room ${conversationId}`);
  });

  // Leave a room
  socket.on('leaveRoom', (conversationId) => {
    socket.leave(conversationId);
    console.log(`User ${socket.data.user.id} left room ${conversationId}`);
  });

  // Handle new message
  socket.on('sendMessage', async (data) => {
    try {
      const message = await messageService.sendMessage({
        senderId: socket.data.user.id,
        conversationId: data.conversationId,
        content: data.content,
        type: data.type,
        attachmentUrl: data.attachmentUrl,
        replyToId: data.replyToId,
      });

      // Broadcast to everyone in the room
      io.to(data.conversationId).emit('receiveMessage', message);

      // Notify all members of this conversation on their personal room
      const members = await prisma.conversationMember.findMany({
        where: { conversationId: data.conversationId },
        select: { userId: true },
      });

      for (const member of members) {
        if (member.userId !== socket.data.user.id) {
          io.to(`user:${member.userId}`).emit('newNotification', {
            type: 'NEW_MESSAGE',
            conversationId: data.conversationId,
            message: message,
          });
        }
      }
    } catch (error) {
      console.error('Error sending message via socket:', error);
      socket.emit('error', 'Could not send message');
    }
  });

  // Typing indicator
  socket.on('typing', (data) => {
    socket.to(data.conversationId).emit('typing', {
      userId: socket.data.user.id,
      isTyping: data.isTyping
    });
  });

  // Handle message reaction
  socket.on('reaction', (data: { conversationId: string; messageId: string; emoji: string }) => {
    try {
      io.to(data.conversationId).emit('messageReaction', {
        messageId: data.messageId,
        userId: socket.data.user.id,
        emoji: data.emoji,
      });
    } catch (error) {
      console.error('Error handling reaction:', error);
    }
  });

  // Handle delete message
  socket.on('deleteMessage', (data: { conversationId: string; messageId: string }) => {
    try {
      io.to(data.conversationId).emit('messageDeleted', {
        messageId: data.messageId,
      });
    } catch (error) {
      console.error('Error deleting message:', error);
    }
  });

  // Handle mark as read
  socket.on('markRead', (data: { conversationId: string }) => {
    try {
      io.to(data.conversationId).emit('messagesRead', {
        conversationId: data.conversationId,
        userId: socket.data.user.id,
      });
    } catch (error) {
      console.error('Error marking as read:', error);
    }
  });

  // Handle initiate call
  socket.on('callUser', (data: { conversationId: string; targetUserId?: string; callerName: string; callerAvatar?: string; isVideo?: boolean }) => {
    try {
      if (data.targetUserId) {
        io.to(`user:${data.targetUserId}`).emit('incomingCall', {
          callerId: socket.data.user.id,
          callerName: data.callerName,
          callerAvatar: data.callerAvatar,
          conversationId: data.conversationId,
          isVideo: data.isVideo ?? false,
        });
      } else {
        socket.to(data.conversationId).emit('incomingCall', {
          callerId: socket.data.user.id,
          callerName: data.callerName,
          callerAvatar: data.callerAvatar,
          conversationId: data.conversationId,
          isVideo: data.isVideo ?? false,
        });
      }
    } catch (error) {
      console.error('Error initiating call:', error);
    }
  });

  // Handle end call
  socket.on('endCall', (data: { conversationId: string; targetUserId?: string }) => {
    try {
      if (data.targetUserId) {
        io.to(`user:${data.targetUserId}`).emit('callEnded', {
          conversationId: data.conversationId,
          userId: socket.data.user.id,
        });
      } else {
        io.to(data.conversationId).emit('callEnded', {
          conversationId: data.conversationId,
          userId: socket.data.user.id,
        });
      }
    } catch (error) {
      console.error('Error ending call:', error);
    }
  });

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.data.user.id}`);
  });
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
