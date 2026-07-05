class TicketHistoryEvent {
  final String id;
  final String fieldName;
  final String? oldValue;
  final String? newValue;
  final String changedById;
  final String changedByName;
  final DateTime changedAt;

  const TicketHistoryEvent({
    required this.id,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.changedById,
    required this.changedByName,
    required this.changedAt,
  });

  factory TicketHistoryEvent.fromJson(Map<String, dynamic> json) {
    try {
      return TicketHistoryEvent(
        id: json['id'] ?? '',
        fieldName: json['fieldName'] ?? '',
        oldValue: json['oldValue'],
        newValue: json['newValue'],
        changedById: json['changedById'] ?? '',
        changedByName: json['changedByName'] ?? 'Unknown',
        changedAt: json['changedAt'] != null
          ? DateTime.parse(json['changedAt'])
          : DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to parse ticket history event: $e');
    }
  }

  static String _humanize(String? value) {
    if (value == null) return 'none';
    return value.replaceAll('_', ' ').toUpperCase();
  }

  String get message {
    switch (fieldName) {
      case 'status':
        if (oldValue == null) {
          return 'Ticket opened by $changedByName';
        }
        return '$changedByName changed status from ${_humanize(oldValue)} to ${_humanize(newValue)}';
      case 'priority':
        return '$changedByName changed priority from ${_humanize(oldValue)} to ${_humanize(newValue)}';
      case 'category':
        return '$changedByName changed category from ${_humanize(oldValue)} to ${_humanize(newValue)}';
      case 'assignedToId':
        if (newValue == null) {
          return '$changedByName unassigned this ticket';
        } else if (changedByName == newValue) {
          return '$changedByName is assigned to this ticket';
        }
        return '$changedByName assigned this ticket to $newValue';
      default:
        return '$changedByName updated $fieldName';
    }
  }
}
