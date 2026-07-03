const Notification = require('../models/Notification');
const logger = require('../utils/logger');

class NotificationController {
  static async list(req, res, next) {
    try {
      const userId = req.user.sub;
      const { page, limit } = req.query;

      const result = await Notification.findByUser(userId, { page, limit });

      res.status(200).json({
        success: true,
        data: result
      });
    } catch (error) {
      logger.error('List notifications error', error.message);
      next(error);
    }
  }

  static async unreadCount(req, res, next) {
    try {
      const userId = req.user.sub;
      const count = await Notification.countUnread(userId);

      res.status(200).json({
        success: true,
        data: { count }
      });
    } catch (error) {
      logger.error('Unread notification count error', error.message);
      next(error);
    }
  }

  static async markRead(req, res, next) {
    try {
      const userId = req.user.sub;
      const { notificationId } = req.params;

      const notification = await Notification.markRead(notificationId, userId);
      if (!notification) {
        return res.status(404).json({
          success: false,
          message: 'Notification not found',
          error: { code: 'NOT_FOUND' }
        });
      }

      res.status(200).json({
        success: true,
        data: notification
      });
    } catch (error) {
      logger.error('Mark notification read error', error.message);
      next(error);
    }
  }

  static async markAllRead(req, res, next) {
    try {
      const userId = req.user.sub;
      await Notification.markAllRead(userId);

      res.status(200).json({
        success: true,
        message: 'All notifications marked as read'
      });
    } catch (error) {
      logger.error('Mark all notifications read error', error.message);
      next(error);
    }
  }
}

module.exports = NotificationController;
