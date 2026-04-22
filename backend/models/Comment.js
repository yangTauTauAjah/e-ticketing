const supabase = require('../config/database');

class Comment {
  static async create(commentData) {
    try {
      const { data, error } = await supabase
        .from('comments')
        .insert([
          {
            ticket_id: commentData.ticketId,
            author_id: commentData.authorId,
            content: commentData.content,
            is_internal: commentData.isInternal || false
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

  static async findById(commentId) {
    try {
      const { data, error } = await supabase
        .from('comments')
        .select(`
          *,
          author:author_id (id, name, email, username)
        `)
        .eq('id', commentId)
        .single();

      if (error && error.code === 'PGRST116') return null;
      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async findByTicket(ticketId) {
    try {
      const { data, error } = await supabase
        .from('comments')
        .select(`
          *,
          author:author_id (id, name, email, username)
        `)
        .eq('ticket_id', ticketId)
        .order('created_at', { ascending: true });

      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async delete(commentId) {
    try {
      const { error } = await supabase
        .from('comments')
        .delete()
        .eq('id', commentId);

      if (error) throw error;

      return true;
    } catch (error) {
      throw error;
    }
  }

  static async update(commentId, updates) {
    try {
      const { data, error } = await supabase
        .from('comments')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', commentId)
        .select()
        .single();

      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Comment;
