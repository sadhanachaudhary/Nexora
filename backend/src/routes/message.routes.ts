import { Router } from 'express';
import { MessageController } from '../controllers/message.controller';
import { authenticateJWT } from '../middleware/auth.middleware';

const router = Router();
const messageController = new MessageController();

router.use(authenticateJWT);

router.get('/:conversationId', messageController.getMessages);
router.post('/:conversationId', messageController.sendMessage);

export default router;
