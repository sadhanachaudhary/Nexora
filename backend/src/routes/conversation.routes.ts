import { Router } from 'express';
import { ConversationController } from '../controllers/conversation.controller';
import { authenticateJWT } from '../middleware/auth.middleware';

const router = Router();
const conversationController = new ConversationController();

router.use(authenticateJWT);

router.get('/', conversationController.getUserConversations);
router.post('/direct', conversationController.createDirectConversation);
router.post('/group', conversationController.createGroupConversation);

export default router;
