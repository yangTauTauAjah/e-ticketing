const User = require('../models/User');
const logger = require('../utils/logger');

class UserController {
  static async getProfile(req, res, next) {
    try {
      const userId = req.user.sub;

      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
          error: { code: 'USER_NOT_FOUND' }
        });
      }

      res.status(200).json({
        success: true,
        data: {
          id: user.id,
          email: user.email,
          username: user.username,
          name: user.name,
          phone: user.phone,
          role: user.role,
          profileImage: user.profile_image_url,
          createdAt: user.created_at
        }
      });
    } catch (error) {
      logger.error('Get profile error', error.message);
      next(error);
    }
  }

  static async updateProfile(req, res, next) {
    try {
      const userId = req.user.sub;
      const { name, phone } = req.validatedBody;

      const updates = {};
      if (name !== undefined) updates.name = name;
      if (phone !== undefined) updates.phone = phone;

      const user = await User.updateProfile(userId, updates);

      logger.info('Profile updated', { userId });

      res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        data: {
          id: user.id,
          name: user.name,
          phone: user.phone,
          updatedAt: user.updated_at
        }
      });
    } catch (error) {
      logger.error('Update profile error', error.message);
      next(error);
    }
  }

  static async changePassword(req, res, next) {
    try {
      const userId = req.user.sub;
      const { currentPassword, newPassword } = req.validatedBody;

      // Get user
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
          error: { code: 'USER_NOT_FOUND' }
        });
      }

      // Verify current password
      const isValidPassword = await User.verifyPassword(currentPassword, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: 'Current password is incorrect',
          error: { code: 'INVALID_CREDENTIALS' }
        });
      }

      // Update password
      await User.updatePassword(userId, newPassword);

      logger.info('Password changed', { userId });

      res.status(200).json({
        success: true,
        message: 'Password changed successfully'
      });
    } catch (error) {
      logger.error('Change password error', error.message);
      next(error);
    }
  }

  static async listHelpdesks(req, res, next) {
    try {
      const helpdesks = await User.findAllByRole('helpdesk');

      res.status(200).json({
        success: true,
        data: helpdesks.map(u => ({
          id: u.id,
          name: u.name,
          email: u.email,
          username: u.username
        }))
      });
    } catch (error) {
      logger.error('List helpdesks error', error.message);
      next(error);
    }
  }

  static async listAll(req, res, next) {
    try {
      const { page, limit, search, role } = req.query;
      const result = await User.findAll({ page, limit, search, role });

      res.status(200).json({
        success: true,
        data: result
      });
    } catch (error) {
      logger.error('List all users error', error.message);
      next(error);
    }
  }

  static async setActive(req, res, next) {
    try {
      const { userId } = req.params;
      const { isActive } = req.body;

      if (typeof isActive !== 'boolean') {
        return res.status(400).json({
          success: false,
          message: 'isActive must be a boolean',
          error: { code: 'INVALID_INPUT' }
        });
      }

      const user = await User.setActive(userId, isActive);

      res.status(200).json({
        success: true,
        message: `User ${isActive ? 'activated' : 'deactivated'} successfully`,
        data: user
      });
    } catch (error) {
      logger.error('Set user active error', error.message);
      next(error);
    }
  }
}

module.exports = UserController;
