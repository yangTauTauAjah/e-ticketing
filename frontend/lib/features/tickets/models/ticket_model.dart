import 'package:e_ticketing/features/tickets/models/comment_model.dart';
import 'package:e_ticketing/features/tickets/models/ticket_history_model.dart';
import 'package:flutter/material.dart';

// Mapping your DB enums to Dart
// ignore: constant_identifier_names
enum TicketStatus { open, in_progress, on_hold, closed, reopened }
enum TicketPriority { low, medium, high, critical }
enum TicketCategory { billing, technical, account, general, featureRequest }

class Ticket {
  final String id;
  final String title;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final String createdById;
  final String createdByName;
  final String? assignedToId;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int commentCount;
  final List<Comment> comments;
  final List<TicketHistoryEvent> history;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdById,
    required this.createdByName,
    this.assignedToId,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    this.commentCount = 0,
    this.comments = const [],
    this.history = const [],
  });
  // Helper to convert snake_case to camelCase enum names
  static String snakeToCamelCase(String input) {
    // e.g., "in_progress" -> "inProgress"
    List<String> parts = input.split('_');
    String camelCase = parts[0];
    for (int i = 1; i < parts.length; i++) {
      camelCase += parts[i][0].toUpperCase() + parts[i].substring(1);
    }
    return camelCase;
  }

  // Factory to convert JSON from /api/v1/tickets to Ticket object
  factory Ticket.fromJson(Map<String, dynamic> json) {
    try {
      var commentList = <Comment>[];
      if (json['comments'] != null) {
        commentList = (json['comments'] as List)
            .map((c) => Comment.fromJson(c))
            .toList();
      }

      var historyList = <TicketHistoryEvent>[];
      if (json['history'] != null) {
        historyList = (json['history'] as List)
            .map((h) => TicketHistoryEvent.fromJson(h))
            .toList();
      }

      // Convert snake_case from backend to camelCase for Dart enums
      String categoryName = Ticket.snakeToCamelCase(json['category'] ?? 'general');
      String priorityName = Ticket.snakeToCamelCase(json['priority'] ?? 'medium');
      String statusName = json['status'] ?? 'open';
      
      return Ticket(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        category: TicketCategory.values.firstWhere(
          (e) => e.name == categoryName,
          orElse: () => TicketCategory.general,
        ),
        priority: TicketPriority.values.firstWhere(
          (e) => e.name == priorityName,
          orElse: () => TicketPriority.medium,
        ),
        status: TicketStatus.values.firstWhere(
          (e) => e.name == statusName,
          orElse: () => TicketStatus.open,
        ),
        createdById: json['createdById'] ?? json['created_by_id'] ?? '',
        createdByName: json['createdByName'] ?? json['created_by_name'] ?? 'Unknown',
        assignedToId: json['assignedToId'] ?? json['assigned_to_id'],
        assignedToName: json['assignedToName'] ?? json['assigned_to_name'],
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
        commentCount: (json['commentCount'] ?? json['comment_count'] ?? 0) as int,
        comments: commentList,
        history: historyList,
      );
    } catch (e) {
      print("Error parsing Ticket JSON: $e");
      throw Exception("Failed to parse ticket data");
    }
  }

  // Helper for UI styling (Status Colors)
  Color get statusColor {
    switch (status) {
      case TicketStatus.open: return Colors.blue;
      case TicketStatus.in_progress: return Colors.orange;
      case TicketStatus.closed: return Colors.green; // Mapping closed/resolved
      default: return Colors.grey;
    }
  }
}