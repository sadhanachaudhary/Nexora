import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class ConversationService {
  async getUserConversations(userId: string) {
    const conversations = await prisma.conversation.findMany({
      where: {
        members: {
          some: {
            userId,
          },
        },
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                name: true,
                avatarUrl: true,
              },
            },
          },
        },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    return conversations;
  }

  async createDirectConversation(userId: string, targetUserId?: string, targetEmail?: string) {
    let resolvedTargetId = targetUserId;
    if (!resolvedTargetId && targetEmail) {
      const targetUser = await prisma.user.findUnique({
        where: { email: targetEmail.trim().toLowerCase() },
      });
      if (!targetUser) {
        throw new Error(`No user found with email "${targetEmail}"`);
      }
      resolvedTargetId = targetUser.id;
    }

    if (!resolvedTargetId) {
      throw new Error('targetUserId or email is required');
    }

    if (userId === resolvedTargetId) {
      throw new Error('Cannot create a conversation with yourself');
    }

    // Check if conversation already exists
    const existingConversations = await prisma.conversation.findMany({
      where: {
        isGroup: false,
        AND: [
          { members: { some: { userId } } },
          { members: { some: { userId: resolvedTargetId } } },
        ],
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                email: true,
                name: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
    });

    if (existingConversations.length > 0) {
      return existingConversations[0];
    }

    // Create new conversation
    const conversation = await prisma.conversation.create({
      data: {
        isGroup: false,
        members: {
          create: [
            { userId },
            { userId: resolvedTargetId },
          ],
        },
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                email: true,
                name: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
    });

    return conversation;
  }
}
