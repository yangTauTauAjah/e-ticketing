const Comment = require('../models/Comment');
const Ticket = require('../models/Ticket');
const logger = require('../utils/logger');

class CommentController {
  static async create(req, res, next) {
    try {
      const { ticketId } = req.params;
      const { content, isInternal } = req.validatedBody;
      const userId = req.user.sub;
      const userRole = req.user.role;

      // Check if ticket exists
      const ticket = await Ticket.findById(ticketId);
      if (!ticket) {
        return res.status(404).json({
          success: false,
          message: 'Ticket not found',
          error: { code: 'TICKET_NOT_FOUND' }
        });
      }

      // Check authorization
      if (userRole === 'user' && ticket.created_by_id !== userId) {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to comment on this ticket',
          error: { code: 'INSUFFICIENT_PERMISSIONS' }
        });
      }

      // Internal comments only for helpdesk/admin
      if (isInternal && userRole === 'user') {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to create internal comments',
          error: { code: 'INSUFFICIENT_PERMISSIONS' }
        });
      }

      // Create comment
      const comment = await Comment.create({
        ticketId,
        authorId: userId,
        content,
        isInternal: isInternal || false
      });

      // Increment comment count
      await Ticket.incrementCommentCount(ticketId);

      logger.info('Comment created', { commentId: comment.id, ticketId, userId });

      res.status(201).json({
        success: true,
        message: 'Comment added successfully',
        data: {
          id: comment.id,
          ticketId,
          content: comment.content,
          authorId: comment.author_id,
          createdAt: comment.created_at
        }
      });
    } catch (error) {
      logger.error('Comment creation error', error.message);
      next(error);
    }
  }

  static async delete(req, res, next) {
    try {
      const { commentId } = req.params;
      const userId = req.user.sub;
      const userRole = req.user.role;

      const comment = await Comment.findById(commentId);
      if (!comment) {
        return res.status(404).json({
          success: false,
          message: 'Comment not found',
          error: { code: 'NOT_FOUND' }
        });
      }

      // Check authorization - only author or admin can delete
      if (userRole !== 'admin' && comment.author_id !== userId) {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to delete this comment',
          error: { code: 'INSUFFICIENT_PERMISSIONS' }
        });
      }

      // Delete comment
      await Comment.delete(commentId);

      // Decrement comment count
      await Ticket.decrementCommentCount(comment.ticket_id);

      logger.info('Comment deleted', { commentId, userId });

      res.status(200).json({
        success: true,
        message: 'Comment deleted successfully'
      });
    } catch (error) {
      logger.error('Comment delete error', error.message);
      next(error);
    }
  }
}

module.exports = CommentController;
