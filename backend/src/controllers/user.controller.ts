import { Request, Response } from 'express';
import { UserService } from '../services/user.service';
import { AuthRequest } from '../middleware/auth.middleware';

export class UserController {
  private userService: UserService;

  constructor() {
    this.userService = new UserService();
  }

  getMe = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user.id;
      const user = await this.userService.getUserById(userId);
      res.status(200).json(user);
    } catch (error: any) {
      res.status(404).json({ error: error.message });
    }
  };

  updateMe = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user.id;
      const user = await this.userService.updateUser(userId, req.body);
      res.status(200).json(user);
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  };

  getAllUsers = async (req: Request, res: Response): Promise<void> => {
    try {
      const search = req.query.search as string;
      const users = await this.userService.getAllUsers(search);
      res.status(200).json(users);
    } catch (error: any) {
      console.error('Error fetching users:', error);
      res.status(500).json({ error: 'Failed to search users. Please try again.' });
    }
  };

  getUserById = async (req: Request, res: Response): Promise<void> => {
    try {
      const user = await this.userService.getUserById(req.params.id);
      res.status(200).json(user);
    } catch (error: any) {
      res.status(404).json({ error: 'User not found' });
    }
  };
}
