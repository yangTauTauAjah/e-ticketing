const supabase = require('../config/database');

class TicketHistory {
  static async create({ ticketId, changedById, fieldName, oldValue, newValue }) {
    try {
      const { data, error } = await supabase
        .from('ticket_history')
        .insert([
          {
            ticket_id: ticketId,
            changed_by_id: changedById,
            field_name: fieldName,
            old_value: oldValue,
            new_value: newValue
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

  static async findByTicket(ticketId) {
    try {
      const { data, error } = await supabase
        .from('ticket_history')
        .select(`
          id,
          field_name,
          old_value,
          new_value,
          changed_by_id,
          changed_by:changed_by_id (id, name),
          changed_at
        `)
        .eq('ticket_id', ticketId)
        .order('changed_at', { ascending: true });

      if (error) throw error;

      return data.map(h => ({
        id: h.id,
        fieldName: h.field_name,
        oldValue: h.old_value,
        newValue: h.new_value,
        changedById: h.changed_by_id,
        changedByName: h.changed_by?.name ?? 'Unknown',
        changedAt: h.changed_at
      }));
    } catch (error) {
      throw error;
    }
  }
}

module.exports = TicketHistory;
