import { Request, Response } from 'express';
import { ConversationService } from '../services/conversation.service';
import { AuthRequest } from '../middleware/auth.middleware';

export class ConversationController {
  private conversationService: ConversationService;

  constructor() {
    this.conversationService = new ConversationService();
  }

  getUserConversations = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user.id;
      const conversations = await this.conversationService.getUserConversations(userId);
      res.status(200).json(conversations);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  };

  createDirectConversation = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user.id;
      const { targetUserId, email } = req.body;

      if (!targetUserId && !email) {
        res.status(400).json({ error: 'targetUserId or email is required' });
        return;
      }

      const conversation = await this.conversationService.createDirectConversation(userId, targetUserId, email);
      res.status(201).json(conversation);
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  };
}
