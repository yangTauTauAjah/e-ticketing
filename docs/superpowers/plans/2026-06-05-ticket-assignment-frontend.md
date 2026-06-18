# Ticket Assignment & Helpdesk Edit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let admins assign tickets to helpdesk users (from the list and detail screens) and give helpdesk users always-visible dropdowns to update ticket status, priority, and category.

**Architecture:** Backend gains a `category` field in the PATCH schema and relaxes the helpdesk guard. Frontend adds a `HelpdeskUser` model + `helpdesksProvider`, converts `TicketDetailScreen` to `ConsumerStatefulWidget` with an immediate-save edit panel, and adds a quick-assign icon + bottom sheet to each ticket card in `TicketListScreen`.

**Tech Stack:** Node.js/Express (backend), Flutter/Dart, Riverpod, Dio, Lucide Icons

---

## File Map

| Action | File |
|--------|------|
| Modify | `backend/controllers/ticketController.js` |
| Modify | `backend/middleware/validation.js` |
| Modify | `frontend/lib/core/constants/api_constants.dart` |
| Create | `frontend/lib/features/tickets/models/helpdesk_user_model.dart` |
| Create | `frontend/lib/features/tickets/providers/helpdesk_provider.dart` |
| Modify | `frontend/lib/features/tickets/screens/ticket_detail_screen.dart` |
| Modify | `frontend/lib/features/tickets/screens/ticket_list_screen.dart` |

---

## Task 1: Backend — Expand helpdesk permissions + add `category` to PATCH

**Files:**
- Modify: `backend/controllers/ticketController.js` (lines 145–218)
- Modify: `backend/middleware/validation.js` (lines 63–71)

### Context

The `update()` method currently:
- Blocks helpdesk from setting `priority` and `assignedToId`
- Does not accept `category` at all

We need helpdesk to set `status`, `priority`, `category` — only `assignedToId` stays admin-only.

- [ ] **Step 1: Update `update()` in `ticketController.js`**

Replace lines 146–171 (the destructure + helpdesk guard + updates block) with:

```js
const { status, priority, category, assignedToId } = req.validatedBody;
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

// Helpdesk may update status, priority, and category; assignedToId is admin-only
if (userRole === 'helpdesk') {
  if (assignedToId !== undefined) {
    return res.status(403).json({
      success: false,
      message: 'Helpdesk users may not assign tickets',
      error: { code: 'INSUFFICIENT_PERMISSIONS' }
    });
  }
}
```

Then replace the `updates` block (lines 194–197) with:

```js
const updates = {};
if (status !== undefined) updates.status = status;
if (priority !== undefined) updates.priority = priority;
if (category !== undefined) updates.category = category;
if (assignedToId !== undefined) updates.assigned_to_id = assignedToId;
```

- [ ] **Step 2: Add `category` to `updateTicket` schema in `validation.js`**

Replace lines 63–71 with:

```js
updateTicket: Joi.object({
  status: Joi.string()
    .valid('open', 'in_progress', 'on_hold', 'closed', 'reopened')
    .optional(),
  priority: Joi.string()
    .valid('low', 'medium', 'high', 'critical')
    .optional(),
  category: Joi.string()
    .valid('billing', 'technical', 'account', 'general', 'feature_request')
    .optional(),
  assignedToId: Joi.string().uuid().allow(null).optional()
}).min(1),
```

- [ ] **Step 3: Manual smoke test**

Start the backend (`node server.js` in `backend/`).

As a helpdesk user, PATCH a ticket with `{ "priority": "high" }` → expect 200.  
As a helpdesk user, PATCH with `{ "assignedToId": "<uuid>" }` → expect 403.  
As an admin, PATCH with `{ "category": "billing" }` → expect 200.

- [ ] **Step 4: Commit**

```bash
git add backend/controllers/ticketController.js backend/middleware/validation.js
git commit -m "feat: allow helpdesk to update priority and category; add category to PATCH schema"
```

---

## Task 2: Frontend data layer — API constant, model, provider

**Files:**
- Modify: `frontend/lib/core/constants/api_constants.dart`
- Create: `frontend/lib/features/tickets/models/helpdesk_user_model.dart`
- Create: `frontend/lib/features/tickets/providers/helpdesk_provider.dart`

### Context

No `helpdesks` endpoint constant exists yet. `helpdesksProvider` fetches `GET /api/v1/users/helpdesks` (admin-only route). The provider is lazy — it only runs when watched, so non-admin screens never trigger the request.

- [ ] **Step 1: Add `helpdesks` constant to `api_constants.dart`**

Replace the file contents with:

```dart
class ApiConstants {
  static const String baseUrl = "http://localhost:5000/api/v1";
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String tickets = "$baseUrl/tickets";
  static const String comments = "$baseUrl/comments";
  static const String helpdesks = "$baseUrl/users/helpdesks";
}
```

- [ ] **Step 2: Create `helpdesk_user_model.dart`**

Create `frontend/lib/features/tickets/models/helpdesk_user_model.dart`:

```dart
class HelpdeskUser {
  final String id;
  final String name;
  final String email;
  final String username;

  const HelpdeskUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
  });

  factory HelpdeskUser.fromJson(Map<String, dynamic> json) {
    return HelpdeskUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
    );
  }
}
```

- [ ] **Step 3: Create `helpdesk_provider.dart`**

Create `frontend/lib/features/tickets/providers/helpdesk_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/features/tickets/models/helpdesk_user_model.dart';

final helpdesksProvider = FutureProvider<List<HelpdeskUser>>((ref) async {
  final dio = ref.read(dioProvider).instance;
  final response = await dio.get(ApiConstants.helpdesks);
  final List list = response.data['data'];
  return list.map((json) => HelpdeskUser.fromJson(json)).toList();
});
```

- [ ] **Step 4: Hot reload and verify no compile errors**

Run `flutter run -d web-server` and confirm the app starts without errors. No UI change yet.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/core/constants/api_constants.dart \
        frontend/lib/features/tickets/models/helpdesk_user_model.dart \
        frontend/lib/features/tickets/providers/helpdesk_provider.dart
git commit -m "feat: add helpdesks API constant, HelpdeskUser model, and helpdesksProvider"
```

---

## Task 3: Ticket detail screen — convert to StatefulWidget + add edit panel

**Files:**
- Modify: `frontend/lib/features/tickets/screens/ticket_detail_screen.dart`

### Context

`TicketDetailScreen` is currently a `ConsumerWidget`. To track which field is currently saving (`_loadingField`), it must become a `ConsumerStatefulWidget`. The old `_buildAdminButton` method is removed. A new white edit-panel card is added below the dark transaction card for helpdesk/admin users.

**Edit panel behaviour:**
- Each dropdown saves immediately on change (no Save button)
- While a PATCH is in flight, `_loadingField == fieldKey` disables that row with a thin `LinearProgressIndicator`
- On error, the provider is NOT invalidated, so the dropdown reverts to the last saved value automatically, and a snackbar appears
- Admin sees a 4th dropdown (ASSIGN TO) populated from `helpdesksProvider`

**Category API value:** `TicketCategory.featureRequest.name` is `"featureRequest"` but the backend expects `"feature_request"`. Use `.replaceAllMapped(RegExp(r'([A-Z])'), (m) => '_\${m.group(0)!.toLowerCase()}')` to convert.

- [ ] **Step 1: Replace the entire file with the new implementation**

Write `frontend/lib/features/tickets/screens/ticket_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/features/tickets/models/ticket_model.dart';
import 'package:e_ticketing/features/tickets/models/helpdesk_user_model.dart';
import 'package:e_ticketing/features/tickets/providers/helpdesk_provider.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_provider.dart';

final ticketDetailProvider = FutureProvider.family<Ticket, String>((ref, id) async {
  final dio = ref.read(dioProvider).instance;
  final response = await dio.get('${ApiConstants.tickets}/$id');
  return Ticket.fromJson(response.data['data']['ticket']);
});

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  String? _loadingField;

  Future<void> _patchTicket(Map<String, dynamic> data, String fieldName) async {
    setState(() => _loadingField = fieldName);
    try {
      final dio = ref.read(dioProvider).instance;
      await dio.patch('${ApiConstants.tickets}/${widget.ticketId}', data: data);
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(ticketsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingField = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final authState = ref.watch(authProvider).value;
    final role = authState?.role ?? 'user';
    final canEdit = role == 'admin' || role == 'helpdesk';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(leading: const BackButton()),
      body: ticketAsync.when(
        data: (ticket) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Dark transaction card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRANSACTION REGISTRY',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    Text('Case ID #${ticket.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('SUBJECT HEADER',
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(ticket.title,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 0,
                      childAspectRatio: 4.0,
                      children: [
                        _buildInfoTile('REPORTER', ticket.createdByName),
                        _buildInfoTile('ASSIGNED TO', ticket.assignedToName ?? 'Unassigned'),
                        _buildInfoTile('STATUS', ticket.status.name.toUpperCase().replaceAll('_', ' ')),
                        _buildInfoTile('CREATED AT', ticket.createdAt.toString().split(' ')[0]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    const Text('DESCRIPTION',
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text(ticket.description,
                      style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.5, height: 1.6)),
                  ],
                ),
              ),

              // Edit panel — helpdesk and admin only
              if (canEdit) ...[
                const SizedBox(height: 24),
                _buildEditPanel(ticket, role),
              ],

              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('COMMENTS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ),
              const SizedBox(height: 24),
              ...ticket.comments.map((c) =>
                _buildCommentBubble(c.authorName, c.content, isMe: c.authorId == authState?.id)),
              const SizedBox(height: 70),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      bottomSheet: _buildReplyBar(),
    );
  }

  Widget _buildEditPanel(Ticket ticket, String role) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MANAGE TICKET',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 2)),
          const SizedBox(height: 16),
          _buildFieldDropdown<TicketStatus>(
            label: 'STATUS',
            fieldKey: 'status',
            value: ticket.status,
            items: TicketStatus.values.map((s) => DropdownMenuItem(
              value: s,
              child: Text(s.name.toUpperCase().replaceAll('_', ' ')),
            )).toList(),
            onChanged: (val) => _patchTicket({'status': val!.name}, 'status'),
          ),
          const SizedBox(height: 12),
          _buildFieldDropdown<TicketPriority>(
            label: 'PRIORITY',
            fieldKey: 'priority',
            value: ticket.priority,
            items: TicketPriority.values.map((p) => DropdownMenuItem(
              value: p,
              child: Text(p.name.toUpperCase()),
            )).toList(),
            onChanged: (val) => _patchTicket({'priority': val!.name}, 'priority'),
          ),
          const SizedBox(height: 12),
          _buildFieldDropdown<TicketCategory>(
            label: 'CATEGORY',
            fieldKey: 'category',
            value: ticket.category,
            items: TicketCategory.values.map((c) => DropdownMenuItem(
              value: c,
              child: Text(
                c.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').toUpperCase(),
              ),
            )).toList(),
            onChanged: (val) {
              // featureRequest -> feature_request for the API
              final apiVal = val!.name.replaceAllMapped(
                RegExp(r'([A-Z])'), (m) => '_${m.group(0)!.toLowerCase()}');
              _patchTicket({'category': apiVal}, 'category');
            },
          ),
          if (role == 'admin') ...[
            const SizedBox(height: 12),
            _buildAssignDropdown(ticket),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldDropdown<T>({
    required String label,
    required String fieldKey,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    final isLoading = _loadingField == fieldKey;
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        ),
        Expanded(
          child: isLoading
            ? const LinearProgressIndicator(minHeight: 2)
            : DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  items: items,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildAssignDropdown(Ticket ticket) {
    final helpdesksAsync = ref.watch(helpdesksProvider);
    return helpdesksAsync.when(
      data: (helpdesks) => _buildFieldDropdown<String?>(
        label: 'ASSIGN TO',
        fieldKey: 'assignedTo',
        value: ticket.assignedToId,
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('UNASSIGNED')),
          ...helpdesks.map((h) => DropdownMenuItem<String?>(
            value: h.id,
            child: Text(h.name.toUpperCase()),
          )),
        ],
        onChanged: (val) => _patchTicket({'assignedToId': val}, 'assignedTo'),
      ),
      loading: () => const Row(
        children: [
          SizedBox(
            width: 84,
            child: Text('ASSIGN TO',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          ),
          SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
      error: (e, _) => const Text('Failed to load helpdesk users',
        style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }

  Widget _buildReplyBar() {
    final controller = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        child: Row(
          children: [
            Expanded(child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'message...', border: InputBorder.none),
            )),
            IconButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                final dio = ref.read(dioProvider).instance;
                await dio.post(
                  '${ApiConstants.comments}/tickets/${widget.ticketId}/comments',
                  data: {'content': text},
                );
                controller.clear();
                ref.invalidate(ticketDetailProvider(widget.ticketId));
              },
              icon: const Icon(LucideIcons.send, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

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
              if (!isMe) Text(author.toUpperCase(),
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
              Text(text,
                style: TextStyle(color: isMe ? Colors.white : const Color(0xFF334155))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
```

- [ ] **Step 2: Hot reload and verify**

Run `flutter run -d web-server`. Open a ticket as admin — you should see:
- The dark card now shows REPORTER, ASSIGNED TO, STATUS, CREATED AT
- A white "MANAGE TICKET" panel below with STATUS, PRIORITY, CATEGORY, ASSIGN TO dropdowns
- Changing STATUS fires a PATCH and the card updates on refresh

Open as helpdesk — ASSIGN TO dropdown should not appear.
Open as user — the MANAGE TICKET panel should not appear at all.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/tickets/screens/ticket_detail_screen.dart
git commit -m "feat: add always-visible edit panel to ticket detail for helpdesk and admin"
```

---

## Task 4: Ticket list screen — admin quick-assign button and bottom sheet

**Files:**
- Modify: `frontend/lib/features/tickets/screens/ticket_list_screen.dart`

### Context

`TicketListScreen` is already a `ConsumerStatefulWidget`. We add:
1. Auth state watch to know if the current user is admin
2. A person-add `IconButton` in the top-right of each ticket card (admin only)
3. `_showAssignSheet(Ticket)` — opens a `ModalBottomSheet` with helpdesk user list
4. `_patchAssign(String ticketId, String? helpdeskId)` — fires PATCH + invalidates list

The `IconButton` absorbs the tap event naturally (Flutter's gesture arena), so the parent card `InkWell` does NOT also navigate to the detail screen when the icon is tapped.

- [ ] **Step 1: Add imports at the top of `ticket_list_screen.dart`**

Add these three import lines after the existing imports:

```dart
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/features/tickets/models/helpdesk_user_model.dart';
import 'package:e_ticketing/features/tickets/providers/helpdesk_provider.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
```

- [ ] **Step 2: Add `_patchAssign` method to `_TicketListScreenState`**

Add this method inside `_TicketListScreenState`, before `build`:

```dart
Future<void> _patchAssign(String ticketId, String? helpdeskId) async {
  try {
    final dio = ref.read(dioProvider).instance;
    await dio.patch('${ApiConstants.tickets}/$ticketId',
        data: {'assignedToId': helpdeskId});
    ref.invalidate(ticketsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment updated')),
      );
    }
  } catch (_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update assignment')),
      );
    }
  }
}
```

- [ ] **Step 3: Add `_showAssignSheet` method to `_TicketListScreenState`**

Add this method immediately after `_patchAssign`:

```dart
void _showAssignSheet(Ticket ticket) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Consumer(
      builder: (ctx, sheetRef, _) {
        final helpdesksAsync = sheetRef.watch(helpdesksProvider);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Assign Helpdesk — ${ticket.title}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            helpdesksAsync.when(
              data: (helpdesks) => Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('Unassigned',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      trailing: ticket.assignedToId == null
                        ? const Icon(LucideIcons.check, size: 16, color: Color(0xFF0F172A))
                        : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _patchAssign(ticket.id, null);
                      },
                    ),
                    ...helpdesks.map((h) => ListTile(
                      title: Text(h.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(h.email,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      trailing: ticket.assignedToId == h.id
                        ? const Icon(LucideIcons.check, size: 16, color: Color(0xFF0F172A))
                        : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _patchAssign(ticket.id, h.id);
                      },
                    )),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading helpdesk users: $e',
                  style: const TextStyle(color: Colors.red)),
              ),
            ),
          ],
        );
      },
    ),
  );
}
```

- [ ] **Step 4: Watch auth state in `build` and pass role to `_buildTicketCard`**

In `_TicketListScreenState.build`, add auth state watch as the first line inside `build`:

```dart
@override
Widget build(BuildContext context) {
  final ticketsAsync = ref.watch(ticketsProvider);
  final authState = ref.watch(authProvider).value;   // ADD THIS
  final isAdmin = authState?.role == 'admin';         // ADD THIS
  // ... rest of build unchanged
```

Then in the `ListView.builder` `itemBuilder`, change:
```dart
itemBuilder: (context, index) => _buildTicketCard(filteredTickets[index]),
```
to:
```dart
itemBuilder: (context, index) => _buildTicketCard(filteredTickets[index], isAdmin),
```

- [ ] **Step 5: Update `_buildTicketCard` signature and add assign button**

Change the method signature from:
```dart
Widget _buildTicketCard(Ticket ticket) {
```
to:
```dart
Widget _buildTicketCard(Ticket ticket, bool isAdmin) {
```

Then replace the top `Row` inside the card (the one with badges and date) with:

```dart
Row(
  children: [
    _buildBadge(ticket.status.name.toUpperCase(), ticket.statusColor),
    const SizedBox(width: 8),
    _buildBadge(ticket.priority.name.toUpperCase(), _getPriorityColor(ticket.priority)),
    const Spacer(),
    if (isAdmin)
      IconButton(
        onPressed: () => _showAssignSheet(ticket),
        icon: const Icon(LucideIcons.userPlus, size: 16, color: Color(0xFF64748B)),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Assign helpdesk',
      ),
    if (isAdmin) const SizedBox(width: 8),
    Text(ticket.createdAt.toString().split(' ')[0],
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
  ],
),
```

Note: The existing `Row` used `mainAxisAlignment: MainAxisAlignment.spaceBetween` — remove that now that we use `Spacer()`.

- [ ] **Step 6: Hot reload and verify**

Run `flutter run -d web-server` as admin. The ticket list should show a small person-add icon on every card. Tapping it opens the bottom sheet. Selecting a helpdesk user updates the assignment and refreshes the list. Tapping the card body still navigates to the detail screen.

Verify as helpdesk or user — the icon should not appear.

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/tickets/screens/ticket_list_screen.dart
git commit -m "feat: add admin quick-assign button and bottom sheet to ticket list"
```

---

## Self-review checklist (run before marking plan complete)

- [ ] Backend: `category` field in both `ticketController` destructure AND `validation.js` schema
- [ ] Backend: helpdesk guard only blocks `assignedToId`, not `priority` or `category`
- [ ] Frontend: `helpdesksProvider` only watched by admin UI (lazy, no wasted request for other roles)
- [ ] Detail screen: `_loadingField` prevents double-tap and shows progress
- [ ] Detail screen: error path does NOT invalidate provider (dropdown reverts naturally)
- [ ] Detail screen: `featureRequest` → `feature_request` conversion applied for category PATCH
- [ ] List screen: `IconButton.onPressed` absorbs tap event (does not trigger card navigation)
- [ ] List screen: bottom sheet correctly highlights current assignment with checkmark
