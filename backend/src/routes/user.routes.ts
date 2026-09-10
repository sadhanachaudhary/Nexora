import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticateJWT } from '../middleware/auth.middleware';

const router = Router();
const userController = new UserController();

router.use(authenticateJWT);

router.get('/me', userController.getMe);
router.put('/me', userController.updateMe);
router.get('/', userController.getAllUsers);
router.get('/:id', userController.getUserById);

export default router;
