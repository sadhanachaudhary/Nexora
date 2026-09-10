import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class MessageService {
  async getMessages(conversationId: string, limit: number = 50, cursor?: string) {
    const messages = await prisma.message.findMany({
      where: { conversationId },
      take: limit,
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      orderBy: { createdAt: 'desc' },
      include: {
        sender: {
          select: {
            id: true,
            username: true,
            name: true,
            avatarUrl: true,
          },
        },
      },
    });

    return messages;
  }

  async sendMessage(data: {
    conversationId: string;
    senderId: string;
    content?: string;
    type?: string;
    attachmentUrl?: string;
    replyToId?: string;
  }) {
    // Verify user is in conversation
    const member = await prisma.conversationMember.findUnique({
      where: {
        userId_conversationId: {
          userId: data.senderId,
          conversationId: data.conversationId,
        },
      },
    });

    if (!member) {
      throw new Error('User is not a member of this conversation');
    }

    const message = await prisma.message.create({
      data: {
        conversationId: data.conversationId,
        senderId: data.senderId,
        content: data.content,
        type: data.type || 'TEXT',
        attachmentUrl: data.attachmentUrl,
        replyToId: data.replyToId,
      },
      include: {
        sender: {
          select: { id: true, username: true, name: true, avatarUrl: true },
        },
      },
    });

    // Update conversation updatedAt
    await prisma.conversation.update({
      where: { id: data.conversationId },
      data: { updatedAt: new Date() },
    });

    return message;
  }
}
