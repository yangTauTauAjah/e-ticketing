# Ticket Assignment & Helpdesk Edit — Frontend Design

**Date:** 2026-06-05  
**Status:** Approved

---

## Goal

Enable admins to assign tickets to helpdesk users (from the ticket list and detail screens), and give helpdesk users always-visible controls to update ticket status, priority, and category.

---

## Scope

| Layer | What changes |
|---|---|
| Backend | Expand helpdesk PATCH permissions; add `category` to update schema |
| Frontend model | New `HelpdeskUser` model |
| Frontend provider | New `helpdesksProvider` |
| Frontend constants | Add `helpdesks` endpoint constant |
| Frontend screen | `TicketDetailScreen` — always-visible edit dropdowns |
| Frontend screen | `TicketListScreen` — admin quick-assign button on card |

---

## 1. Backend Changes

### 1.1 `backend/controllers/ticketController.js` — `update()` method

**Current helpdesk guard (blocks priority and assignedToId):**
```js
const { status, priority, assignedToId } = req.validatedBody;
const attemptedAdminFields = [priority, assignedToId].some(v => v !== undefined);
```

**New (helpdesk may update status, priority, category; assignedToId is admin-only):**
```js
const { status, priority, category, assignedToId } = req.validatedBody;
const attemptedAdminFields = [assignedToId].some(v => v !== undefined);
```

Add `category` to the updates object:
```js
if (status !== undefined) updates.status = status;
if (priority !== undefined) updates.priority = priority;
if (category !== undefined) updates.category = category;
if (assignedToId !== undefined) updates.assigned_to_id = assignedToId;
```

### 1.2 `backend/middleware/validation.js` — `updateTicket` schema

Add `category` to the Joi schema:
```js
updateTicket: Joi.object({
  status: Joi.string().valid('open','in_progress','on_hold','closed','reopened').optional(),
  priority: Joi.string().valid('low','medium','high','critical').optional(),
  category: Joi.string().valid('billing','technical','account','general','feature_request').optional(),
  assignedToId: Joi.string().uuid().allow(null).optional()
}).min(1),
```

**Permission matrix after change:**

| Field | user | helpdesk | admin |
|---|---|---|---|
| status | ✗ | ✓ | ✓ |
| priority | ✗ | ✓ | ✓ |
| category | ✗ | ✓ | ✓ |
| assignedToId | ✗ | ✗ | ✓ |

---

## 2. Frontend — New Data Layer

### 2.1 New model: `frontend/lib/features/tickets/models/helpdesk_user_model.dart`

Simple data class for a user with `role = 'helpdesk'`. Fields: `id`, `name`, `email`, `username`. Has `fromJson` factory.

### 2.2 New provider: `frontend/lib/features/tickets/providers/helpdesk_provider.dart`

```
final helpdesksProvider = FutureProvider<List<HelpdeskUser>>
```

Calls `GET /api/v1/users/helpdesks`. Lazy — only evaluated when watched. Only watched by admin UI, so no wasted request for helpdesk/user roles.

### 2.3 API constant: `frontend/lib/core/constants/api_constants.dart`

Add:
```dart
static const String helpdesks = '$baseUrl/users/helpdesks';
```

---

## 3. Frontend — Ticket Detail Screen

File: `frontend/lib/features/tickets/screens/ticket_detail_screen.dart`

### 3.1 Role-based edit section

Rendered below the existing ticket info card, above the comments section. Visibility:

- **user role** → section not shown (read-only, no change to current behaviour)
- **helpdesk role** → 3 dropdowns: Status, Priority, Category
- **admin role** → 4 dropdowns: Status, Priority, Category, Assign To

### 3.2 Dropdown behaviour (each field)

Each dropdown is independent. On `onChanged`:

1. Optimistically update local state (dropdown shows new value immediately)
2. Disable the dropdown (prevent double-tap) while request is in flight
3. `PATCH /api/v1/tickets/:ticketId` with the single changed field
4. On success: re-enable dropdown, invalidate `ticketsProvider` and `ticketDetailProvider(ticketId)`
5. On error: revert to previous value, re-enable dropdown, show error snackbar

### 3.3 Assign To dropdown (admin only)

- Watches `helpdesksProvider`
- Shows a loading spinner while helpdesk list is fetching
- Options: `"Unassigned"` (sends `assignedToId: null`) + one entry per helpdesk user
- Currently assigned helpdesk is pre-selected based on `ticket.assignedToId`
- Same immediate-save behaviour as other dropdowns

---

## 4. Frontend — Ticket List Screen

File: `frontend/lib/features/tickets/screens/ticket_list_screen.dart`

### 4.1 Quick-assign button on ticket card (admin only)

A small icon button (person-add icon) rendered in the trailing area of each ticket card. Only rendered when `authState?.role == 'admin'`.

- Tapping the icon calls `stopPropagation` equivalent (`GestureDetector` wrapping the icon to absorb taps before they reach the card's `onTap`)
- Tapping the card body still navigates to `TicketDetailScreen` as before

### 4.2 Assignment bottom sheet

Opened by tapping the assign icon. Contents:

- Title: `"Assign Helpdesk"` + truncated ticket title
- Watches `helpdesksProvider` — shows `CircularProgressIndicator` while loading
- First list tile: `"Unassigned"` (clears assignment)
- Remaining tiles: one per helpdesk user, showing name + email as subtitle
- Currently assigned user is indicated with a trailing checkmark
- Tapping a tile:
  1. Fires `PATCH /api/v1/tickets/:ticketId` with `{ assignedToId: selectedId }`
  2. Closes the bottom sheet
  3. Invalidates `ticketsProvider` to refresh the list
  4. Shows success/error snackbar

---

## 5. Error Handling

| Scenario | Behaviour |
|---|---|
| PATCH returns 403 | Revert dropdown, snackbar: "Permission denied" |
| PATCH returns 400 (INVALID_HELPDESK_USER) | Revert dropdown, snackbar: "Invalid helpdesk user" |
| PATCH returns 404 | Snackbar: "Ticket not found" |
| Network error | Revert dropdown, snackbar: "Network error, try again" |
| `helpdesksProvider` fails | Show error text in dropdown / bottom sheet with retry |

---

## 6. Files Changed / Created

| Action | File |
|---|---|
| Modify | `backend/controllers/ticketController.js` |
| Modify | `backend/middleware/validation.js` |
| Create | `frontend/lib/features/tickets/models/helpdesk_user_model.dart` |
| Create | `frontend/lib/features/tickets/providers/helpdesk_provider.dart` |
| Modify | `frontend/lib/core/constants/api_constants.dart` |
| Modify | `frontend/lib/features/tickets/screens/ticket_detail_screen.dart` |
| Modify | `frontend/lib/features/tickets/screens/ticket_list_screen.dart` |
