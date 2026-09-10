import { Request, Response } from 'express';
import { MessageService } from '../services/message.service';
import { AuthRequest } from '../middleware/auth.middleware';

export class MessageController {
  private messageService: MessageService;

  constructor() {
    this.messageService = new MessageService();
  }

  getMessages = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
      const conversationId = req.params.conversationId as string;
      const limit = parseInt(req.query.limit as string) || 50;
      const cursor = req.query.cursor as string;

      const messages = await this.messageService.getMessages(conversationId, limit, cursor);
      res.status(200).json(messages);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  };

  sendMessage = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
      const senderId = req.user.id;
      const conversationId = req.params.conversationId as string;
      const { content, type, attachmentUrl, replyToId } = req.body;

      if (!content && !attachmentUrl) {
        res.status(400).json({ error: 'Message must have content or attachment' });
        return;
      }

      const message = await this.messageService.sendMessage({
        conversationId,
        senderId,
        content,
        type,
        attachmentUrl,
        replyToId,
      });

      res.status(201).json(message);
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  };
}
