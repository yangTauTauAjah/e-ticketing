# Helpdesk Role Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Activate the `helpdesk` role so that admins can assign a dedicated helpdesk user to each ticket, and helpdesk users can update ticket status.

**Architecture:** Add a dedicated `helpdesk_id` foreign key column to `tickets` (separate from the existing `assigned_to_id`). Split the `PATCH /tickets/:id` permission check so `admin` controls all fields while `helpdesk` may only set `status`. Expose a `GET /users/helpdesks` endpoint (admin-only) so the client can list available helpdesk users for the assignment UI.

**Tech Stack:** Node.js, Express 5, Supabase (PostgreSQL), Joi validation, JWT-based role claims (`req.user.role`)

---

## File Map


| Action | File                                      | What changes                                                                                          |
| -------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Create | `backend/migrations/add_helpdesk_id.sql`  | ALTER TABLE migration for production DB                                                               |
| Modify | `backend/migrations/init.sql`             | Add`helpdesk_id` column so fresh setups include it                                                    |
| Modify | `backend/models/Ticket.js`                | Include helpdesk join in`findById` + `list`; map `helpdeskId`/`helpdeskName` in responses             |
| Modify | `backend/middleware/validation.js`        | Add`helpdeskId` field to `updateTicket` schema                                                        |
| Modify | `backend/controllers/ticketController.js` | Split update() permissions; fix getDetail() comment mapping bug; include helpdesk fields in responses |
| Modify | `backend/models/User.js`                  | Add`findAllByRole(role)` static method                                                                |
| Modify | `backend/controllers/userController.js`   | Add`listHelpdesks()` handler                                                                          |
| Modify | `backend/routes/userRoutes.js`            | Add`GET /helpdesks` route guarded by `roleMiddleware(['admin'])`                                      |

---

## Task 1: Database — Add `helpdesk_id` Column to `tickets`

**Files:**

- Create: `backend/migrations/add_helpdesk_id.sql`
- Modify: `backend/migrations/init.sql:25-50`

The `tickets` table currently has `assigned_to_id` for generic assignment. We add `helpdesk_id` as a dedicated FK that points to a user with `role = 'helpdesk'`. Constraint enforcement at the DB level is not applied (role check is done at the application layer).

- [X] **Step 1: Create the migration file**

Create `backend/migrations/add_helpdesk_id.sql` with:

```sql
-- Migration: add helpdesk_id to tickets
-- Run this once against your Supabase database via the SQL editor or psql.

ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS helpdesk_id UUID REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_tickets_helpdesk_id ON tickets(helpdesk_id);
```

- [X] **Step 2: Update `init.sql` so fresh setups include the column**

In `backend/migrations/init.sql`, inside the `CREATE TABLE IF NOT EXISTS tickets` block, add `helpdesk_id` after `assigned_to_id`:

```sql
  created_by_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_to_id UUID REFERENCES users(id) ON DELETE SET NULL,
  helpdesk_id UUID REFERENCES users(id) ON DELETE SET NULL,
```

Also add the index after the existing `idx_tickets_assigned_to` line:

```sql
CREATE INDEX idx_tickets_helpdesk_id ON tickets(helpdesk_id);
```

- [X] **Step 3: Run the migration against Supabase**

Open the Supabase SQL editor for your project, paste the contents of `add_helpdesk_id.sql`, and execute. Confirm with:

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tickets' AND column_name = 'helpdesk_id';
```

Expected output: one row with `helpdesk_id | uuid`.

- [ ] **Step 4: Commit**

```bash
git add backend/migrations/add_helpdesk_id.sql backend/migrations/init.sql
git commit -m "feat: add helpdesk_id column to tickets table"
```

---

## Task 2: Update Ticket Model — Include Helpdesk in Queries

**Files:**

- Modify: `backend/models/Ticket.js`

`findById` and `list` need to join on `helpdesk_id` so the controller can return `helpdeskId` and `helpdeskName` in responses.

- [ ] **Step 1: Update `findById` to join helpdesk user**

In `backend/models/Ticket.js`, replace the `.select(...)` block inside `findById` (lines 33–38):

```js
const { data, error } = await supabase
  .from('tickets')
  .select(`
    *,
    created_by:created_by_id (id, name, email, username),
    assigned_to:assigned_to_id (id, name, email, username),
    helpdesk:helpdesk_id (id, name, email, username),
    comments (count)
  `)
  .eq('id', ticketId)
  .single();
```

- [ ] **Step 2: Update `list` query to select and map helpdesk fields**

Replace the `.select(...)` block inside `list` (lines 53–69) with:

```js
let query = supabase
  .from('tickets')
  .select(`
    id,
    title,
    description,
    category,
    priority,
    status,
    created_by_id,
    created_by:created_by_id (id, name, email, username),
    assigned_to_id,
    assigned_to:assigned_to_id (id, name, email, username),
    helpdesk_id,
    helpdesk:helpdesk_id (id, name, email, username),
    created_at,
    updated_at,
    comment_count
  `, { count: 'exact' });
```

- [ ] **Step 3: Add `helpdeskId` and `helpdeskName` to the `list` response map**

Replace the `return` block's `tickets.map(...)` (lines 113–128):

```js
return {
  tickets: data.map(ticket => ({
    id: ticket.id,
    title: ticket.title,
    description: ticket.description,
    category: ticket.category,
    priority: ticket.priority,
    status: ticket.status,
    createdById: ticket.created_by.id,
    createdByName: ticket.created_by.name,
    assignedToId: ticket.assigned_to_id,
    assignedToName: ticket.assigned_to?.name,
    helpdeskId: ticket.helpdesk_id,
    helpdeskName: ticket.helpdesk?.name ?? null,
    createdAt: ticket.created_at,
    updatedAt: ticket.updated_at,
    commentCount: ticket.comment_count
  })),
  pagination: {
    page,
    limit,
    total: count,
    pages: Math.ceil(count / limit)
  }
};
```

- [ ] **Step 4: Remove the stray `console.log(data)` on line 111**

Delete the line:

```js
console.log(data)
```

- [ ] **Step 5: Commit**

```bash
git add backend/models/Ticket.js
git commit -m "feat: include helpdesk join in ticket queries and responses"
```

---

## Task 3: Update Validation Schema — Add `helpdeskId`

**Files:**

- Modify: `backend/middleware/validation.js:63-71`

The `updateTicket` Joi schema must accept `helpdeskId` (the controller enforces who can actually send it).

- [ ] **Step 1: Add `helpdeskId` to the `updateTicket` schema**

Replace the `updateTicket` schema (lines 63–71):

```js
updateTicket: Joi.object({
  status: Joi.string()
    .valid('open', 'in_progress', 'on_hold', 'closed', 'reopened')
    .optional(),
  priority: Joi.string()
    .valid('low', 'medium', 'high', 'critical')
    .optional(),
  assignedToId: Joi.string().uuid().optional(),
  helpdeskId: Joi.string().uuid().allow(null).optional()
}).min(1),
```

- [ ] **Step 2: Commit**

```bash
git add backend/middleware/validation.js
git commit -m "feat: add helpdeskId field to updateTicket validation schema"
```

---

## Task 4: Update Ticket Controller — Role-Split `update()` + Fix `getDetail()`

**Files:**

- Modify: `backend/controllers/ticketController.js`

**Current behaviour:**

- `update()` line 149: only `admin` passes — helpdesk is blocked entirely.
- `getDetail()` lines 101–111: `filteredComments` is mapped correctly for non-users, but for `user` role it reassigns to raw `comments` (not mapped), causing objects with DB snake_case instead of camelCase to be sent — a latent bug fixed here.

**New behaviour:**

- `helpdesk` and `admin` can both reach the update handler.
- `helpdesk` may only set `status`; any other fields in the body are rejected with 403.
- `admin` can set `status`, `priority`, `assignedToId`, and `helpdeskId`.
  - When setting `helpdeskId`, admin must provide a UUID. The controller verifies the target user has `role = 'helpdesk'` before saving.
- `getDetail()` comment filter fixed and helpdesk fields added to response.

- [ ] **Step 1: Replace `update()` method in ticketController.js**

Replace the entire `static async update(req, res, next)` block (lines 141–190):

```js
static async update(req, res, next) {
  try {
    const { ticketId } = req.params;
    const { status, priority, assignedToId, helpdeskId } = req.validatedBody;
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

    // Helpdesk may only update status
    if (userRole === 'helpdesk') {
      const attemptedAdminFields = [priority, assignedToId, helpdeskId].some(
        (v) => v !== undefined
      );
      if (attemptedAdminFields) {
        return res.status(403).json({
          success: false,
          message: 'Helpdesk users may only update ticket status',
          error: { code: 'INSUFFICIENT_PERMISSIONS' }
        });
      }
    }

    const ticket = await Ticket.findById(ticketId);
    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
        error: { code: 'TICKET_NOT_FOUND' }
      });
    }

    // Validate that helpdeskId targets a helpdesk-role user (admin only path)
    if (helpdeskId !== undefined && helpdeskId !== null) {
      const User = require('../models/User');
      const targetUser = await User.findById(helpdeskId);
      if (!targetUser || targetUser.role !== 'helpdesk') {
        return res.status(400).json({
          success: false,
          message: 'The specified user is not a helpdesk member',
          error: { code: 'INVALID_HELPDESK_USER' }
        });
      }
    }

    const updates = {};
    if (status !== undefined) updates.status = status;
    if (priority !== undefined) updates.priority = priority;
    if (assignedToId !== undefined) updates.assigned_to_id = assignedToId;
    if (helpdeskId !== undefined) updates.helpdesk_id = helpdeskId;

    const updatedTicket = await Ticket.update(ticketId, updates);

    logger.info('Ticket updated', { ticketId, userId, updates });

    res.status(200).json({
      success: true,
      message: 'Ticket updated successfully',
      data: {
        id: updatedTicket.id,
        status: updatedTicket.status,
        priority: updatedTicket.priority,
        helpdeskId: updatedTicket.helpdesk_id,
        updatedAt: updatedTicket.updated_at
      }
    });
  } catch (error) {
    logger.error('Ticket update error', error.message);
    next(error);
  }
}
```

- [ ] **Step 2: Fix `getDetail()` — comment mapping bug + add helpdesk to response**

Replace the entire `static async getDetail(req, res, next)` block (lines 72–138):

```js
static async getDetail(req, res, next) {
  try {
    const { ticketId } = req.params;
    const userId = req.user.sub;
    const userRole = req.user.role;

    const ticket = await Ticket.findById(ticketId);
    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found',
        error: { code: 'TICKET_NOT_FOUND' }
      });
    }

    // Users can only view their own tickets
    if (userRole === 'user' && ticket.created_by_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to view this ticket',
        error: { code: 'INSUFFICIENT_PERMISSIONS' }
      });
    }

    const attachments = await Attachment.findByTicket(ticketId);
    const comments = await Comment.findByTicket(ticketId);

    // Users cannot see internal comments
    const visibleComments = userRole === 'user'
      ? comments.filter(c => !c.is_internal)
      : comments;

    const mappedComments = visibleComments.map(c => ({
      id: c.id,
      content: c.content,
      authorId: c.author_id,
      authorName: c.author.name,
      isInternal: c.is_internal,
      createdAt: c.created_at,
      updatedAt: c.updated_at,
      attachments: c.attachments || []
    }));

    res.status(200).json({
      success: true,
      data: {
        ticket: {
          id: ticket.id,
          title: ticket.title,
          description: ticket.description,
          category: ticket.category,
          priority: ticket.priority,
          status: ticket.status,
          createdById: ticket.created_by_id,
          createdByName: ticket.created_by?.name,
          assignedToId: ticket.assigned_to_id,
          assignedToName: ticket.assigned_to?.name,
          helpdeskId: ticket.helpdesk_id,
          helpdeskName: ticket.helpdesk?.name ?? null,
          createdAt: ticket.created_at,
          updatedAt: ticket.updated_at,
          attachments,
          comments: mappedComments
        }
      }
    });
  } catch (error) {
    logger.error('Ticket detail error', error.message);
    next(error);
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add backend/controllers/ticketController.js
git commit -m "feat: split update permissions for helpdesk/admin; add helpdeskId to ticket responses; fix comment mapping bug"
```

---

## Task 5: List All Helpdesk Users (Admin-Only Endpoint)

**Files:**

- Modify: `backend/models/User.js`
- Modify: `backend/controllers/userController.js`
- Modify: `backend/routes/userRoutes.js`

Admin needs to fetch all helpdesk users to populate an assignment picker. Endpoint: `GET /api/v1/users/helpdesks`.

- [ ] **Step 1: Add `findAllByRole` to User model**

In `backend/models/User.js`, add this static method before the closing `}` of the `User` class (after `verifyPassword`):

```js
static async findAllByRole(role) {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('id, name, email, username, role')
      .eq('role', role)
      .eq('is_active', true)
      .order('name', { ascending: true });

    if (error) throw error;

    return data;
  } catch (error) {
    throw error;
  }
}
```

- [ ] **Step 2: Add `listHelpdesks` handler to UserController**

In `backend/controllers/userController.js`, add this static method before the closing `}` of the `UserController` class:

```js
static async listHelpdesks(req, res, next) {
  try {
    const helpdesks = await User.findAllByRole('helpdesk');

    res.status(200).json({
      success: true,
      data: helpdesks.map(u => ({
        id: u.id,
        name: u.name,
        email: u.email,
        username: u.username
      }))
    });
  } catch (error) {
    logger.error('List helpdesks error', error.message);
    next(error);
  }
}
```

- [ ] **Step 3: Add route in userRoutes.js**

In `backend/routes/userRoutes.js`, import `roleMiddleware` and add the new route. Replace the file contents with:

```js
const express = require('express');
const UserController = require('../controllers/userController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');
const { validate, schemas } = require('../middleware/validation');

const router = express.Router();

router.use(authMiddleware);

router.get('/profile', UserController.getProfile);
router.patch('/profile', validate(schemas.updateProfile), UserController.updateProfile);
router.post('/change-password', validate(schemas.changePassword), UserController.changePassword);
router.get('/helpdesks', roleMiddleware(['admin']), UserController.listHelpdesks);

module.exports = router;
```

- [ ] **Step 4: Commit**

```bash
git add backend/models/User.js backend/controllers/userController.js backend/routes/userRoutes.js
git commit -m "feat: add GET /users/helpdesks endpoint for admin to list helpdesk users"
```

---

## Task 6: Manual Verification Checklist

No automated tests exist in this project yet. Verify each scenario using the Postman collection at `backend/E-Ticketing-API.postman_collection.json` or curl.

**Setup:** Ensure you have three accounts in Supabase:

- `user_a` with `role = 'user'`
- `helpdesk_a` with `role = 'helpdesk'`
- `admin_a` with `role = 'admin'`

You can set roles directly in the Supabase table editor or via a SQL UPDATE.

- [ ] **Ticket creation (user_a)** — `POST /api/v1/tickets`

  - Expected: 201, `helpdesk_id` is `null` in Supabase row.
- [ ] **List helpdesks (admin_a)** — `GET /api/v1/users/helpdesks`

  - Expected: 200, array containing `helpdesk_a`.
- [ ] **List helpdesks (helpdesk_a)** — `GET /api/v1/users/helpdesks`

  - Expected: 403 `INSUFFICIENT_PERMISSIONS`.
- [ ] **Assign helpdesk to ticket (admin_a)** — `PATCH /api/v1/tickets/:id` body `{ "helpdeskId": "<helpdesk_a_id>" }`

  - Expected: 200, response includes `helpdeskId`.
  - Confirm in Supabase that `helpdesk_id` column is set on that row.
- [ ] **Assign non-helpdesk user as helpdesk (admin_a)** — `PATCH /api/v1/tickets/:id` body `{ "helpdeskId": "<user_a_id>" }`

  - Expected: 400 `INVALID_HELPDESK_USER`.
- [ ] **Helpdesk updates status (helpdesk_a)** — `PATCH /api/v1/tickets/:id` body `{ "status": "in_progress" }`

  - Expected: 200.
- [ ] **Helpdesk tries to set priority (helpdesk_a)** — `PATCH /api/v1/tickets/:id` body `{ "priority": "critical" }`

  - Expected: 403 `INSUFFICIENT_PERMISSIONS`.
- [ ] **Helpdesk tries to assign helpdeskId (helpdesk_a)** — `PATCH /api/v1/tickets/:id` body `{ "helpdeskId": "<some_id>" }`

  - Expected: 403 `INSUFFICIENT_PERMISSIONS`.
- [ ] **User tries to update ticket (user_a)** — `PATCH /api/v1/tickets/:id` body `{ "status": "closed" }`

  - Expected: 403 `INSUFFICIENT_PERMISSIONS`.
- [ ] **Get ticket detail — helpdesk fields present** — `GET /api/v1/tickets/:id`

  - Expected: response includes `helpdeskId` and `helpdeskName`.
- [ ] **Get ticket list — helpdesk fields present** — `GET /api/v1/tickets`

  - Expected: each ticket object includes `helpdeskId` and `helpdeskName`.
- [ ] **Commit**

```bash
git add .
git commit -m "chore: verified helpdesk role implementation end-to-end"
```

---

## Summary of Permission Matrix (After Implementation)


| Action                    | user     | helpdesk | admin  |
| --------------------------- | ---------- | ---------- | -------- |
| Create ticket             | ✓       | ✓       | ✓     |
| List all tickets          | own only | ✓ all   | ✓ all |
| View ticket detail        | own only | ✓       | ✓     |
| Update ticket status      | ✗       | ✓       | ✓     |
| Update ticket priority    | ✗       | ✗       | ✓     |
| Assign helpdesk to ticket | ✗       | ✗       | ✓     |
| Assign`assigned_to_id`    | ✗       | ✗       | ✓     |
| Delete ticket             | own only | ✗       | ✓     |
| List helpdesk users       | ✗       | ✗       | ✓     |
