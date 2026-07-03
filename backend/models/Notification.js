const supabase = require('../config/database');

class Notification {
  static async createMany(entries) {
    if (!entries.length) return [];
    try {
      const { data, error } = await supabase
        .from('notifications')
        .insert(entries.map(e => ({
          user_id: e.userId,
          ticket_id: e.ticketId ?? null,
          type: e.type,
          title: e.title,
          message: e.message
        })))
        .select();

      if (error) throw error;
      return data;
    } catch (error) {
      throw error;
    }
  }

  static async findByUser(userId, { page = 1, limit = 30 } = {}) {
    try {
      const from = (page - 1) * limit;
      const to = from + limit - 1;

      const { data, error, count } = await supabase
        .from('notifications')
        .select('*', { count: 'exact' })
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .range(from, to);

      if (error) throw error;

      return {
        notifications: data,
        pagination: { page, limit, total: count, pages: Math.ceil(count / limit) }
      };
    } catch (error) {
      throw error;
    }
  }

  static async countUnread(userId) {
    try {
      const { count, error } = await supabase
        .from('notifications')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('is_read', false);

      if (error) throw error;
      return count ?? 0;
    } catch (error) {
      throw error;
    }
  }

  static async markRead(id, userId) {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

      if (error && error.code === 'PGRST116') return null;
      if (error) throw error;
      return data;
    } catch (error) {
      throw error;
    }
  }

  static async markAllRead(userId) {
    try {
      const { error } = await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('user_id', userId)
        .eq('is_read', false);

      if (error) throw error;
      return true;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Notification;
