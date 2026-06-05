# E-Ticketing Helpdesk — API Documentation

**Version**: 1.0  
**Base URL**: `http://localhost:5000/api/v1`  
**Authentication**: JWT Bearer Token  
**Content-Type**: `application/json`  
**HTTP Client (Flutter)**: Dio with auto-injected `Authorization` header via interceptor

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Authentication](#authentication)
   - [Register](#1-register)
   - [Login](#2-login)
   - [Logout](#3-logout-client-side)
3. [Tickets](#tickets)
   - [List Tickets](#4-list-tickets)
   - [Get Ticket Detail](#5-get-ticket-detail)
   - [Create Ticket](#6-create-ticket)
   - [Update Ticket Status](#7-update-ticket-status)
4. [Comments](#comments)
   - [Add Comment](#8-add-comment)
5. [File Upload](#file-upload)
   - [Upload File](#9-upload-file)
6. [Error Handling](#error-handling)
7. [Authorization Rules](#authorization-rules)
8. [Rate Limits](#rate-limits)
9. [Known Issues & Notes](#known-issues--notes)

---

## Getting Started

### Base URL

| Environment | URL |
|-------------|-----|
| Local | `http://localhost:5000/api/v1` |

Defined in [`lib/core/constants/api_constants.dart`](../frontend/lib/core/constants/api_constants.dart):

```dart
static const String baseUrl = "http://localhost:5000/api/v1";
```

### Authentication

All protected endpoints require a JWT token passed as a Bearer token in the `Authorization` header. The Flutter Dio client injects this automatically from `FlutterSecureStorage` on every request:

```
Authorization: Bearer <jwt_token>
```

The token is obtained from the login response and stored locally under the key `jwt_token`. Tokens expire after **24 hours** — after which the user must log in again.

### Response Envelope

All responses follow this consistent envelope:

```json
{
  "success": true | false,
  "message": "Human-readable description",
  "data": { ... }
}
```

---

## Authentication

### 1. Register

**`POST /auth/register`**

Creates a new user account. Does **not** automatically log the user in — a separate login request is required after registration.

> **Note**: The Flutter app auto-derives the `username` field from `name` (lowercased, spaces stripped). Example: `"John Doe"` → `"johndoe"`.

**Request Body**

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `name` | string | Yes | Display name |
| `username` | string | Yes | Lowercase, no spaces, 3–50 chars, alphanumeric + underscore only, must be unique |
| `email` | string | Yes | Valid email format, must be unique |
| `password` | string | Yes | Min 8 chars, must include uppercase, lowercase, number, and special character |
| `phone` | string | No | 10+ digits, numbers only |

**Example Request**

```json
{
  "name": "John Doe",
  "username": "johndoe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "phone": "1234567890"
}
```

**Response `201 Created`**

```json
{
  "success": true,
  "message": "User registered successfully"
}
```

**Error `409 Conflict`** — email or username already taken

```json
{
  "success": false,
  "message": "Email already exists"
}
```

---

### 2. Login

**`POST /auth/login`**

Authenticates the user and returns a JWT token. The Flutter app stores the token in `FlutterSecureStorage` and extracts `id`, `role`, and `name` into app state.

**Request Body**

| Field | Type | Required |
|-------|------|----------|
| `email` | string | Yes |
| `password` | string | Yes |

**Example Request**

```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response `200 OK`**

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "role": "user",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

The `role` field controls UI access. Valid values:

| Role | Description |
|------|-------------|
| `user` | Regular ticket submitter |
| `helpdesk` | Support agent — can update/assign tickets |
| `admin` | Full access |

**Error `401 Unauthorized`**

```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

---

### 3. Logout *(client-side)*

Logout is handled entirely on the client. The Flutter app:

1. Deletes the JWT token from `FlutterSecureStorage`
2. Resets the `AuthNotifier` state to unauthenticated
3. Navigates to the login screen

**No API call is made.** If server-side session invalidation is needed, a `POST /auth/logout` endpoint should be added.

---

## Tickets

All ticket endpoints require `Authorization: Bearer {token}`.

---

### 4. List Tickets

**`GET /tickets`**

Returns a list of tickets. Regular users see only their own tickets; `helpdesk` and `admin` roles see all tickets.

**Query Parameters sent by Flutter**

| Parameter | Value | Description |
|-----------|-------|-------------|
| `limit` | `10` | Results per page |
| `sortBy` | `created_at` | Sort field |
| `sortOrder` | `desc` | Sort direction |

Additional supported parameters (not yet used in the Flutter UI):

| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | integer | Page number (default: `1`) |
| `status` | string | Filter: `open`, `in_progress`, `on_hold`, `closed`, `reopened` |
| `priority` | string | Filter: `low`, `medium`, `high`, `critical` |
| `search` | string | Search in title and description |

**Example Request**

```
GET /tickets?limit=10&sortBy=created_at&sortOrder=desc
```

**Response `200 OK`**

```json
{
  "success": true,
  "data": {
    "tickets": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Login issue",
        "description": "Cannot login to my account",
        "category": "technical",
        "priority": "high",
        "status": "open",
        "createdById": "uuid",
        "createdByName": "John Doe",
        "assignedToId": "uuid",
        "assignedToName": "Support Agent",
        "createdAt": "2026-04-16T10:00:00Z",
        "updatedAt": "2026-04-16T10:30:00Z",
        "commentCount": 3
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 45,
      "pages": 5
    }
  }
}
```

**Ticket field types as parsed by Flutter**

| Field | Dart Type | Notes |
|-------|-----------|-------|
| `id` | `String` (UUID) | |
| `title` | `String` | |
| `description` | `String` | |
| `category` | `TicketCategory` enum | `billing`, `technical`, `account`, `general`, `feature_request` — backend sends snake_case, Flutter converts to camelCase enum |
| `priority` | `TicketPriority` enum | `low`, `medium`, `high`, `critical` |
| `status` | `TicketStatus` enum | `open`, `in_progress`, `on_hold`, `closed`, `reopened` |
| `createdById` / `created_by_id` | `String` | Flutter accepts both casing |
| `createdByName` / `created_by_name` | `String` | Flutter accepts both casing |
| `assignedToId` / `assigned_to_id` | `String?` | Nullable |
| `assignedToName` / `assigned_to_name` | `String?` | Nullable |
| `createdAt` | `DateTime` | ISO 8601 string |
| `updatedAt` | `DateTime` | ISO 8601 string |
| `commentCount` / `comment_count` | `int` | Flutter accepts both casing |

---

### 5. Get Ticket Detail

**`GET /tickets/:ticketId`**

Returns a single ticket with its full comment thread and attachments.

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `ticketId` | UUID | ID of the ticket |

**Response `200 OK`**

```json
{
  "success": true,
  "data": {
    "ticket": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Login issue",
      "description": "Cannot login to my account",
      "category": "technical",
      "priority": "high",
      "status": "in_progress",
      "createdById": "uuid",
      "createdByName": "John Doe",
      "assignedToId": "uuid",
      "assignedToName": "Support Agent",
      "createdAt": "2026-04-16T10:00:00Z",
      "updatedAt": "2026-04-16T12:00:00Z",
      "attachments": [
        {
          "id": "uuid",
          "fileName": "screenshot.png",
          "fileType": "image/png",
          "fileSize": 245000,
          "fileUrl": "https://cdn.example.com/attachments/uuid.png",
          "uploadedAt": "2026-04-16T10:05:00Z",
          "isImage": true
        }
      ],
      "comments": [
        {
          "id": "uuid",
          "content": "We are investigating this issue",
          "authorId": "uuid",
          "authorName": "Support Agent",
          "createdAt": "2026-04-16T10:30:00Z"
        }
      ]
    }
  }
}
```

**Comment field types as parsed by Flutter**

| Field | Dart Type | Notes |
|-------|-----------|-------|
| `id` | `String` | |
| `content` | `String` | |
| `authorId` / `author_id` | `String` | Flutter accepts both casing |
| `authorName` / `author_name` | `String` | Flutter accepts both casing |
| `createdAt` / `created_at` | `DateTime` | Flutter accepts both casing |

---

### 6. Create Ticket

**`POST /tickets`**

Submits a new support ticket. Optionally attaches previously uploaded file IDs.

**Request Body**

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `title` | string | Yes | 5–255 characters |
| `description` | string | Yes | Min 10 characters |
| `category` | string | Yes | `billing`, `technical`, `account`, `general`, `feature_request` |
| `priority` | string | Yes | `low`, `medium`, `high`, `critical` |
| `attachments` | array of strings | No | Array of file IDs returned from `POST /upload`. Empty array if no files. |

**Example Request**

```json
{
  "title": "Access credentials expired",
  "description": "My login credentials stopped working after the system update yesterday. Getting an 'Invalid credentials' error even though the password is correct.",
  "category": "technical",
  "priority": "high",
  "attachments": ["550e8400-e29b-41d4-a716-446655440000"]
}
```

**Response `201 Created`**

```json
{
  "success": true,
  "message": "Ticket created successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Access credentials expired",
    "status": "open",
    "createdAt": "2026-04-16T10:00:00Z"
  }
}
```

---

### 7. Update Ticket Status

**`PATCH /tickets/:ticketId`**

Updates the status of a ticket. Only accessible to users with `admin` or `helpdesk` roles. The Flutter UI shows action buttons for these roles on the ticket detail screen.

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `ticketId` | UUID | ID of the ticket |

**Request Body**

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `status` | string | Yes (from Flutter) | `open`, `in_progress`, `on_hold`, `closed`, `reopened` |
| `priority` | string | No | `low`, `medium`, `high`, `critical` |
| `assignedToId` | UUID | No | ID of the helpdesk agent |

**Example Request** *(as sent from Flutter)*

```json
{
  "status": "in_progress"
}
```

**Response `200 OK`**

```json
{
  "success": true,
  "message": "Ticket updated successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "in_progress",
    "updatedAt": "2026-04-16T12:00:00Z"
  }
}
```

**Error `403 Forbidden`** — non-admin/helpdesk users

```json
{
  "success": false,
  "message": "Insufficient permissions"
}
```

---

## Comments

### 8. Add Comment

**`POST /comments/tickets/:ticketId/comments`**

Adds a comment to a ticket. Visible in the ticket thread to all parties.

> ⚠️ **URL Note**: The Flutter app constructs this URL as `${ApiConstants.comments}/tickets/:ticketId/comments`, which resolves to `/api/v1/comments/tickets/:ticketId/comments`. Verify this matches your router definition — it differs from a conventional `/api/v1/tickets/:ticketId/comments` pattern.

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `ticketId` | UUID | ID of the ticket to comment on |

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `content` | string | Yes | Comment text |

**Example Request**

```json
{
  "content": "I tried resetting my password but the issue persists."
}
```

**Response `201 Created`**

```json
{
  "success": true,
  "message": "Comment added successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "ticketId": "uuid",
    "content": "I tried resetting my password but the issue persists.",
    "authorId": "uuid",
    "authorName": "John Doe",
    "createdAt": "2026-04-16T10:30:00Z"
  }
}
```

---

## File Upload

### 9. Upload File

**`POST /upload`**

Uploads a file and returns an attachment ID to reference when creating a ticket. The Flutter app calls this before `POST /tickets` when the user has selected an image.

**Headers**

```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Form Data**

| Key | Value |
|-----|-------|
| `file` | Binary file data (sent with filename `evidence.jpg`) |

**Supported File Types**

| Type | MIME |
|------|------|
| JPEG | `image/jpeg` |
| PNG | `image/png` |
| GIF | `image/gif` |
| WebP | `image/webp` |
| PDF | `application/pdf` |

**Max file size**: 50 MB

**Response `201 Created`**

```json
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "fileName": "evidence.jpg",
    "fileType": "image/jpeg",
    "fileSize": 184320,
    "fileUrl": "https://cdn.example.com/attachments/uuid.jpg"
  }
}
```

The `data.id` value is passed in the `attachments` array when creating a ticket.

---

## Error Handling

All error responses follow this structure:

```json
{
  "success": false,
  "message": "Human-readable error description",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional context if available"
  }
}
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| `200` | Success |
| `201` | Resource created |
| `400` | Bad request or validation error |
| `401` | Unauthorized — token missing or invalid |
| `403` | Forbidden — role lacks required permission |
| `404` | Resource not found |
| `409` | Conflict — e.g. duplicate email or username |
| `422` | Unprocessable entity — validation failed |
| `429` | Rate limit exceeded |
| `500` | Internal server error |

### Error Codes

| Code | Description |
|------|-------------|
| `INVALID_CREDENTIALS` | Login email or password is wrong |
| `USER_NOT_FOUND` | User does not exist |
| `EMAIL_EXISTS` | Email already registered |
| `USERNAME_EXISTS` | Username already taken |
| `INVALID_TOKEN` | JWT token is invalid or expired |
| `INSUFFICIENT_PERMISSIONS` | Role lacks the required permission |
| `TICKET_NOT_FOUND` | Ticket does not exist |
| `INVALID_FILE_SIZE` | File exceeds the 50 MB limit |
| `FILE_TYPE_NOT_ALLOWED` | File type is not supported |

---

## Authorization Rules

| Action | user | helpdesk | admin |
|--------|:----:|:--------:|:-----:|
| Register / Login | ✓ | ✓ | ✓ |
| Create tickets | ✓ | ✓ | ✓ |
| View own tickets | ✓ | ✓ | ✓ |
| Comment on tickets | ✓ | ✓ | ✓ |
| Upload attachments | ✓ | ✓ | ✓ |
| View all tickets | — | ✓ | ✓ |
| Update ticket status / priority | — | ✓ | ✓ |
| Assign tickets | — | ✓ | ✓ |
| Delete tickets | — | — | ✓ |
| Manage users | — | — | ✓ |

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| `POST /auth/login` | 5 requests per 15 minutes per IP |
| `POST /upload` | 10 requests per hour per user |
| All other endpoints | 1000 requests per hour per user |

Exceeding a limit returns `429 Too Many Requests`.

---

## Known Issues & Notes

### Comment endpoint URL

The Flutter app calls:

```
POST /api/v1/comments/tickets/:ticketId/comments
```

constructed from `ApiConstants.comments` (`/api/v1/comments`) + `/tickets/:ticketId/comments`.

A conventional REST design would place this at:

```
POST /api/v1/tickets/:ticketId/comments
```

Confirm your backend router matches the URL the Flutter app is calling, or update `ApiConstants.comments` accordingly.

### Reset password screen

The reset password screen (`ResetPasswordScreen`) currently uses a **mock delay** and does not call any API endpoint. A `POST /auth/reset-password` endpoint needs to be wired up before this feature is functional.

### JWT expiry

Tokens expire after 24 hours. The Flutter app has no automatic token refresh — on expiry the user must log in again. Consider adding a refresh token flow if session longevity is required.

---

*Generated from Flutter frontend source — [`lib/`](../frontend/lib/)*
