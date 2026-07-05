const supabase = require('../config/database');

class Ticket {
  static async create(ticketData) {
    try {
      const { data, error } = await supabase
        .from('tickets')
        .insert([
          {
            title: ticketData.title,
            description: ticketData.description,
            category: ticketData.category,
            priority: ticketData.priority || 'medium',
            assigned_to_id: ticketData.assignedToId || null,
            status: 'open',
            created_by_id: ticketData.createdById
          }
        ])
        .select()
        .single();

      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async findById(ticketId) {
    try {
      const { data, error } = await supabase
        .from('tickets')
        .select(`
          *,
          created_by:created_by_id (id, name, email, username),
          assigned_to:assigned_to_id (id, name, email, username),
          comments (count)
        `)
        .eq('id', ticketId)
        .single();

      if (error && error.code === 'PGRST116') return null;
      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async list(filters = {}) {
    try {
      let query = supabase
        .from('tickets')
        .select(`
          id,
          title,
          description,
          category,
          priority,
          status,
          created_by_id,
          created_by:created_by_id (id, name, email, username),
          assigned_to_id,
          assigned_to:assigned_to_id (id, name, email, username),
          created_at,
          updated_at,
          comment_count
        `, { count: 'exact' });

      // Apply filters
      if (filters.status) {
        const statuses = filters.status.split(',');
        query = query.in('status', statuses);
      }

      if (filters.priority) {
        const priorities = filters.priority.split(',');
        query = query.in('priority', priorities);
      }

      if (filters.search) {
        query = query.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`);
      }

      if (filters.createdById) {
        query = query.eq('created_by_id', filters.createdById);
      }

      if (filters.assignedToId) {
        query = query.eq('assigned_to_id', filters.assignedToId);
      }

      // Sorting
      const sortBy = filters.sortBy || 'created_at';
      const sortOrder = filters.sortOrder === 'asc' ? { ascending: true } : { ascending: false };
      query = query.order(sortBy, sortOrder);

      // Pagination
      const page = parseInt(filters.page) || 1;
      const limit = parseInt(filters.limit) || 10;
      const from = (page - 1) * limit;
      const to = from + limit - 1;

      query = query.range(from, to);

      const { data, error, count } = await query;

      if (error) throw error;

      return {
        tickets: data.map(ticket => ({
          id: ticket.id,
          title: ticket.title,
          description: ticket.description,
          category: ticket.category,
          priority: ticket.priority,
          status: ticket.status,
          createdById: ticket.created_by.id,
          createdByName: ticket.created_by.name,
          assignedToId: ticket.assigned_to_id,
          assignedToName: ticket.assigned_to?.name ?? null,
          createdAt: ticket.created_at,
          updatedAt: ticket.updated_at,
          commentCount: ticket.comment_count
        })),
        pagination: {
          page,
          limit,
          total: count,
          pages: Math.ceil(count / limit)
        }
      };
    } catch (error) {
      throw error;
    }
  }

  static async stats(filters = {}) {
    try {
      const statuses = ['open', 'in_progress', 'on_hold', 'closed', 'reopened'];
      const counts = {};

      for (const status of statuses) {
        let query = supabase
          .from('tickets')
          .select('id', { count: 'exact', head: true })
          .eq('status', status);

        if (filters.createdById) query = query.eq('created_by_id', filters.createdById);
        if (filters.assignedToId) query = query.eq('assigned_to_id', filters.assignedToId);

        const { count, error } = await query;
        if (error) throw error;
        counts[status] = count ?? 0;
      }

      return {
        total: Object.values(counts).reduce((a, b) => a + b, 0),
        ...counts
      };
    } catch (error) {
      throw error;
    }
  }

  static async update(ticketId, updates) {
    try {
      const { data, error } = await supabase
        .from('tickets')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', ticketId)
        .select()
        .single();

      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async delete(ticketId) {
    try {
      const { error } = await supabase
        .from('tickets')
        .delete()
        .eq('id', ticketId);

      if (error) throw error;

      return true;
    } catch (error) {
      throw error;
    }
  }

  static async incrementCommentCount(ticketId) {
    try {
      const ticket = await this.findById(ticketId);
      if (!ticket) return null;

      return await this.update(ticketId, {
        comment_count: (ticket.comment_count || 0) + 1
      });
    } catch (error) {
      throw error;
    }
  }

  static async decrementCommentCount(ticketId) {
    try {
      const ticket = await this.findById(ticketId);
      if (!ticket) return null;

      const newCount = Math.max(0, (ticket.comment_count || 0) - 1);
      return await this.update(ticketId, {
        comment_count: newCount
      });
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Ticket;
