import { Router, Request, Response } from 'express';
import { MessageService } from '../services/message.service';

const router = Router();
const messageService = new MessageService();

/**
 * POST /api/webhooks/:conversationId
 * Allows external services (GitHub, CI/CD, Stripe, Sentry, Custom Scripts)
 * to send structured notification cards directly into a Nexora channel.
 */
router.post('/:conversationId', async (req: Request, res: Response) => {
  try {
    const { conversationId } = req.params;
    const {
      service = 'Webhook',
      event = 'Notification',
      title = 'External Event Triggered',
      description = '',
      status = 'success', // 'success' | 'warning' | 'error' | 'info'
      fields = [],
      actionUrl = ''
    } = req.body;

    const payload = JSON.stringify({
      service,
      event,
      title,
      description,
      status,
      fields,
      actionUrl,
      timestamp: new Date().toISOString()
    });

    // In a real system, the webhook acts as a system sender or bot
    // We persist message with type WEBHOOK
    const message = await messageService.sendMessage({
      senderId: 'system-bot',
      conversationId,
      content: payload,
      type: 'WEBHOOK'
    });

    res.status(200).json({
      success: true,
      messageId: message.id,
      timestamp: message.createdAt
    });
  } catch (error: any) {
    console.error('Error processing incoming webhook:', error);
    res.status(500).json({
      error: 'Failed to process webhook payload',
      details: error.message
    });
  }
});

export default router;
