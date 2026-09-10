import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class UserService {
  async getUserById(id: string) {
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        bio: true,
        avatarUrl: true,
        createdAt: true,
      }
    });
    if (!user) {
      throw new Error('User not found');
    }
    return user;
  }

  async getAllUsers(search?: string) {
    const trimmed = search?.trim();
    const whereClause = trimmed
      ? {
          OR: [
            { username: { contains: trimmed } },
            { name: { contains: trimmed } },
            { email: { contains: trimmed } },
          ],
        }
      : {};

    const users = await prisma.user.findMany({
      where: whereClause,
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        avatarUrl: true,
      },
      take: 20,
    });
    return users;
  }

  async updateUser(id: string, data: { name?: string; bio?: string; avatarUrl?: string }) {
    const user = await prisma.user.update({
      where: { id },
      data: {
        name: data.name,
        bio: data.bio,
        avatarUrl: data.avatarUrl,
      },
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        bio: true,
        avatarUrl: true,
        createdAt: true,
      }
    });
    return user;
  }
}
