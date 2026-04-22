const supabase = require('../config/database');

class Attachment {
  static async create(attachmentData) {
    try {
      const { data, error } = await supabase
        .from('attachments')
        .insert([
          {
            ticket_id: attachmentData.ticketId || null,
            comment_id: attachmentData.commentId || null,
            file_name: attachmentData.fileName,
            file_type: attachmentData.fileType,
            file_size: attachmentData.fileSize,
            file_url: attachmentData.fileUrl,
            uploaded_by_id: attachmentData.uploadedById
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

  static async findById(attachmentId) {
    try {
      const { data, error } = await supabase
        .from('attachments')
        .select('*')
        .eq('id', attachmentId)
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
        .from('attachments')
        .select('*')
        .eq('ticket_id', ticketId)
        .order('uploaded_at', { ascending: false });

      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async findByComment(commentId) {
    try {
      const { data, error } = await supabase
        .from('attachments')
        .select('*')
        .eq('comment_id', commentId)
        .order('uploaded_at', { ascending: false });

      if (error) throw error;

      return data;
    } catch (error) {
      throw error;
    }
  }

  static async delete(attachmentId) {
    try {
      const { error } = await supabase
        .from('attachments')
        .delete()
        .eq('id', attachmentId);

      if (error) throw error;

      return true;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = Attachment;
