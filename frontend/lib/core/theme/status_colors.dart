import 'package:flutter/material.dart';
import 'package:e_ticketing/features/tickets/models/ticket_model.dart';

/// Single source of truth for ticket status/priority colors, matching the
/// Figma "Implement Dark Theme UI" palette. Used instead of each screen
/// re-declaring its own (previously inconsistent) status color mapping.
class StatusColors {
  const StatusColors._();

  static const open = Color(0xFF4ADE80);
  static const assigned = Color(0xFFFB923C);
  static const inProgress = Color(0xFFFACC15);
  static const closed = Color(0xFF6B7280);
  static const reopened = Color(0xFFF87171);

  static const priorityLow = Color(0xFF4ADE80);
  static const priorityMedium = Color(0xFFFACC15);
  static const priorityHigh = Color(0xFFF87171);
  static const priorityCritical = Color(0xFFA78BFA);

  static Color forStatus(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return open;
      case TicketStatus.assigned:
        return assigned;
      case TicketStatus.in_progress:
        return inProgress;
      case TicketStatus.closed:
        return closed;
      case TicketStatus.reopened:
        return reopened;
    }
  }

  static Color forStatusName(String? name) {
    switch (name) {
      case 'open':
        return open;
      case 'assigned':
        return assigned;
      case 'in_progress':
        return inProgress;
      case 'closed':
        return closed;
      case 'reopened':
        return reopened;
      default:
        return closed;
    }
  }

  static Color forPriority(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return priorityLow;
      case TicketPriority.medium:
        return priorityMedium;
      case TicketPriority.high:
        return priorityHigh;
      case TicketPriority.critical:
        return priorityCritical;
    }
  }
}
