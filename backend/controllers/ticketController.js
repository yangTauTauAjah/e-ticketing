const Ticket = require('../models/Ticket');
const Attachment = require('../models/Attachment');
const Comment = require('../models/Comment');
const User = require('../models/User');
const logger = require('../utils/logger');

class TicketController {
  static async create(req, res, next) {
    try {
      const { title, description, category, priority, attachments } = req.validatedBody;
      const userId = req.user.sub;

      // Create ticket
      const ticket = await Ticket.create({
        title,
        description,
        category,
        priority: priority || 'medium',
        createdById: userId
      });

      logger.info('Ticket created', { ticketId: ticket.id, userId });

      res.status(201).json({
        success: true,
        message: 'Ticket created successfully',
        data: {
          id: ticket.id,
          title: ticket.title,
          status: ticket.status,
          createdAt: ticket.created_at
        }
      });
    } catch (error) {
      logger.error('Ticket creation error', error.message);
      next(error);
    }
  }

  static async list(req, res, next) {
    try {
      const userId = req.user.sub;
      const userRole = req.user.role;
      const { page, limit, status, priority, search, sortBy, sortOrder } = req.query;

      // Users can only see their own tickets unless they're helpdesk/admin
      const filters = {
        page,
        limit,
        status,
        priority,
        search,
        sortBy,
        sortOrder
      };

      if (userRole === 'user') {
        filters.createdById = userId;
      }

      const result = await Ticket.list(filters);

      res.status(200).json({
        success: true,
        data: result
      });
    } catch (error) {
      logger.error('Ticket list error', error.message);
      next(error);
    }
  }

  static async getDetail(req, res, next) {
    try {
      const { ticketId } = req.params;
      const userId = req.user.sub;
      const userRole = req.user.role;

      const ticket = await Ticket.findById(ticketId);
      if (!ticket) {
        return res.status(404).json({
          success: false,
          message: 'Ticket not found',
          error: { code: 'TICKET_NOT_FOUND' }
        });
      }

      // Users can only view their own tickets
      if (userRole === 'user' && ticket.created_by_id !== userId) {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to view this ticket',
          error: { code: 'INSUFFICIENT_PERMISSIONS' }
        });
      }

      const attachments = await Attachment.findByTicket(ticketId);
      const comments = await Comment.findByTicket(ticketId);

      // Users cannot see internal comments
      const visibleComments = userRole === 'user'
        ? comments.filter(c => !c.is_internal)
        : comments;

      const mappedComments = visibleComments.map(c => ({
        id: c.id,
        content: c.content,
        authorId: c.author_id,
        authorName: c.author.name,
        isInternal: c.is_internal,
        createdAt: c.created_at,
        updatedAt: c.updated_at,
        attachments: c.attachments || []
      }));

      res.status(200).json({
        success: true,
        data: {
          ticket: {
            id: ticket.id,
            title: ticket.title,
            description: ticket.description,
            category: ticket.category,
            priority: ticket.priority,
            status: ticket.status,
            createdById: ticket.created_by_id,
            createdByName: ticket.created_by?.name,
            assignedToId: ticket.assigned_to_id,
            assignedToName: ticket.assigned_to?.name ?? null,
            createdAt: ticket.created_at,
            updatedAt: ticket.updated_at,
            attachments,
            comments: mappedComments
          }
        }
      });
    } catch (error) {
      logger.error('Ticket detail error', error.message);
      next(error);
    }
  }

  static async update(req, res, next) {
    try {
      const { ticketId } = req.params;
      const { status, priority, assignedToId } = req.validatedBody;
      const userId = req.user.sub;
      const userRole = req.user.role;

      // Only admin and helpdesk can update tickets
      if (userRole !== 'admin' && userRole !== 'helpdesk') {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to update tickets',
          error: { code: 'INSUFFICIENT_PERMISSIONS' }
        });
      }

      // Helpdesk may only update status
      if (userRole === 'helpdesk') {
        const attemptedAdminFields = [priority, assignedToId].some(
          (v) => v !== undefined
        );
        if (attemptedAdminFields) {
          return res.status(403).json({
            success: false,
            message: 'Helpdesk users may only update ticket status',
            error: { code: 'INSUFFICIENT_PERMISSIONS' }
          });
        }
      }

      const ticket = await Ticket.findById(ticketId);
      if (!ticket) {
        return res.status(404).json({
          success: false,
          message: 'Ticket not found',
          error: { code: 'TICKET_NOT_FOUND' }
        });
      }

      // Validate that assignedToId targets a helpdesk-role user (admin only path)
      if (assignedToId !== undefined && assignedToId !== null) {
        const targetUser = await User.findById(assignedToId);
        if (!targetUser || targetUser.role !== 'helpdesk' || !targetUser.is_active) {
          return res.status(400).json({
            success: false,
            message: 'The specified user is not a helpdesk member',
            error: { code: 'INVALID_HELPDESK_USER' }
          });
        }
      }

      const updates = {};
      if (status !== undefined) updates.status = status;
      if (priority !== undefined) updates.priority = priority;
      if (assignedToId !== undefined) updates.assigned_to_id = assignedToId;

      const updatedTicket = await Ticket.update(ticketId, updates);

      logger.info('Ticket updated', { ticketId, userId, updates });

      res.status(200).json({
        success: true,
        message: 'Ticket updated successfully',
        data: {
          id: updatedTicket.id,
          status: updatedTicket.status,
          priority: updatedTicket.priority,
          assignedToId: updatedTicket.assigned_to_id,
          updatedAt: updatedTicket.updated_at
        }
      });
    } catch (error) {
      logger.error('Ticket update error', error.message);
      next(error);
    }
  }

  static async delete(req, res, next) {
    try {
      const { ticketId } = req.params;
      const userId = req.user.sub;
      const userRole = req.user.role;

      const ticket = await Ticket.findById(ticketId);
      if (!ticket) {
        return res.status(404).json({
          success: false,
          message: 'Ticket not found',
          error: { code: 'TICKET_NOT_FOUND' }
        });
      }

      if (userRole !== 'admin') {
        if (userRole !== 'user' || ticket.created_by_id !== userId) {
          return res.status(403).json({
            success: false,
            message: 'You do not have permission to delete this ticket',
            error: { code: 'INSUFFICIENT_PERMISSIONS' }
          });
        }
      }

      await Ticket.delete(ticketId);

      logger.info('Ticket deleted', { ticketId, userId });

      res.status(200).json({
        success: true,
        message: 'Ticket deleted successfully'
      });
    } catch (error) {
      logger.error('Ticket delete error', error.message);
      next(error);
    }
  }
}

module.exports = TicketController;
