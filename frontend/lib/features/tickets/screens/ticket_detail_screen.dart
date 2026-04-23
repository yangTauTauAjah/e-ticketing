import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/features/tickets/models/ticket_model.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_provider.dart';

// Use a family provider to fetch data by ID
final ticketDetailProvider = FutureProvider.family<Ticket, String>((ref, id) async {
  try {
    final dio = ref.read(dioProvider).instance;
    final response = await dio.get('${ApiConstants.tickets}/$id');
    return Ticket.fromJson(response.data['data']['ticket']);
  } catch (e) {
    throw Exception("Failed to load ticket details");
  }
});

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;
  
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final authState = ref.watch(authProvider).value;
    final isAdmin = authState?.role == 'admin' || authState?.role == 'helpdesk'; //

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(leading: const BackButton()),
      body: ticketAsync.when(
        data: (ticket) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Dark Transaction Registry Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), 
                  borderRadius: BorderRadius.circular(32)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TRANSACTION REGISTRY", 
                      style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    Text("Case ID #${ticket.id.substring(0, 8).toUpperCase()}", 
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("SUBJECT HEADER", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(ticket.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    // 2x2 Grid for Ticket Details
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 0,
                      childAspectRatio: 4.0,
                      children: [
                        _buildInfoTile("REPORTER", ticket.createdByName),
                        _buildInfoTile("PRIORITY", ticket.priority.name.toUpperCase(), isPriority: true),
                        _buildInfoTile("CATEGORY", ticket.category.name.replaceAll('_', ' ').toUpperCase()),
                        _buildInfoTile("CREATED AT", ticket.createdAt.toString().split(' ')[0]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),

                    // Description Section
                    const Text("DESCRIPTION", 
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text(ticket.description, 
                      style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.5, height: 1.6)),
                  ],
                ),
              ),

              // ROLE-BASED ACTION BUTTONS
              if (isAdmin) const SizedBox(height: 24),
              if (isAdmin) 
                Row(
                  children: [
                    Expanded(child: _buildAdminButton(ref, ticket.status.name, "IN PROGRESS", ticket.status == TicketStatus.in_progress ? ticket.statusColor : Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAdminButton(ref, ticket.status.name, "CLOSED", ticket.status == TicketStatus.closed ? ticket.statusColor : Colors.green)), // Hex for emerald
                  ],
                ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("COMMENTS", 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ),
              
              const SizedBox(height: 24),
              // Comment list from backend
              ...ticket.comments.map((comment) => 
                _buildCommentBubble(
                  comment.authorName, 
                  comment.content, 
                  isMe: comment.authorId == authState?.id
                )
              )/* .toList() */,
              const SizedBox(height: 70)
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
      bottomSheet: _buildReplyBar(ref),
    );
  }
  
  // Admin button updates status via PATCH /api/v1/tickets/:ticketId
  Widget _buildAdminButton(WidgetRef ref, String currentStatus,String label, Color color) {
    String statusValue = label.toLowerCase().replaceAll(' ', '_');
    return InkWell(
      onTap: () async {
        final dio = ref.read(dioProvider).instance;
        await dio.patch('${ApiConstants.tickets}/$ticketId', data: {'status': label.toLowerCase().replaceAll(' ', '_')});
        ref.invalidate(ticketDetailProvider(ticketId)); // Refresh ticket detail
        ref.invalidate(ticketsProvider); // Refresh ticket list
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: statusValue == currentStatus ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: color.withValues(alpha: 0.2))
        ),
        child: Center(child: Text(label, style: TextStyle(color: statusValue == currentStatus ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 10))),
      ),
    );
  }

  // Reply bar sends content to POST /api/v1/tickets/:ticketId/comments
  Widget _buildReplyBar(WidgetRef ref) {
    final controller = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(32), 
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)]
        ),
        child: Row(
          children: [
            Expanded(child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "message...", border: InputBorder.none)
            )),
            IconButton(
              onPressed: () async {
                final dio = ref.read(dioProvider).instance;
                await dio.post('${ApiConstants.comments}/tickets/$ticketId/comments', data: {'content': controller.text});
                controller.clear();
                ref.invalidate(ticketDetailProvider(ticketId));
              },
              icon: const Icon(LucideIcons.send, color: Color(0xFF0F172A))
            ),
          ],
        ),
      ),
    );
  }

  // UI helper functions remain consistent with your design
  Widget _buildCommentBubble(String author, String text, {bool isMe = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(20).copyWith(
              topLeft: isMe ? const Radius.circular(20) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(!isMe) Text(author.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
              Text(text, style: TextStyle(color: isMe ? Colors.white : const Color(0xFF334155))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {bool isPriority = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isPriority) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            if (isPriority) const SizedBox(width: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}