# E-Ticketing Helpdesk Backend System Specification

**Technology Stack**: Node.js + Express.js + Supabase (PostgreSQL)  
**API Style**: RESTful with JWT Authentication  
**Environment**: Production-ready with security best practices

---

## 1. Project Setup & Architecture

### 1.1 Technology Stack
```
Runtime: Node.js 18+
Framework: Express.js 4.x
Database: Supabase (PostgreSQL 15+)
Authentication: JWT (jsonwebtoken)
Password Hashing: bcrypt
Validation: joi / express-validator
CORS: cors
Environment: dotenv
```

### 1.2 Folder Structure
```
backend/
├── config/
│   ├── database.js          # Supabase connection
│   ├── jwt.js               # JWT configuration
│   └── environment.js       # Environment variables
├── controllers/
│   ├── authController.js
│   ├── ticketController.js
│   ├── commentController.js
│   └── userController.js
├── routes/
│   ├── authRoutes.js
│   ├── ticketRoutes.js
│   ├── commentRoutes.js
│   └── userRoutes.js
├── middleware/
│   ├── authMiddleware.js
│   ├── errorHandler.js
│   └── validation.js
├── models/
│   ├── User.js
│   ├── Ticket.js
│   ├── Comment.js
│   └── Attachment.js
├── utils/
│   ├── logger.js
│   ├── emailService.js
│   └── fileUpload.js
├── migrations/
│   └── init.sql            # Database schema
├── .env
├── .env.example
├── server.js               # Entry point
└── package.json
```

---

## 2. Database Schema (Supabase PostgreSQL)

### 2.1 Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('user', 'helpdesk', 'admin')),
  profile_image_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
  CONSTRAINT phone_format CHECK (phone IS NULL OR phone ~* '^[0-9]{10,}$')
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
```

### 2.2 Tickets Table
```sql
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(50) NOT NULL CHECK (category IN ('billing', 'technical', 'account', 'general', 'feature_request')),
  priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'on_hold', 'closed', 'reopened')),
  
  created_by_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_to_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP,
  
  comment_count INTEGER DEFAULT 0,
  is_urgent BOOLEAN DEFAULT FALSE,
  
  CONSTRAINT valid_created_by CHECK (created_by_id IS NOT NULL)
);

CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_tickets_created_by ON tickets(created_by_id);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to_id);
CREATE INDEX idx_tickets_created_at ON tickets(created_at DESC);
```

### 2.3 Comments Table
```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  is_internal BOOLEAN DEFAULT FALSE,
  
  CONSTRAINT non_empty_content CHECK (LENGTH(TRIM(content)) > 0)
);

CREATE INDEX idx_comments_ticket ON comments(ticket_id);
CREATE INDEX idx_comments_author ON comments(author_id);
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);
```

### 2.4 Attachments Table
```sql
CREATE TABLE attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(50) NOT NULL,
  file_size INTEGER NOT NULL,
  file_url TEXT NOT NULL,
  
  uploaded_by_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  is_image BOOLEAN GENERATED ALWAYS AS (
    file_type IN ('image/jpeg', 'image/png', 'image/gif', 'image/webp')
  ) STORED,
  is_document BOOLEAN GENERATED ALWAYS AS (
    file_type IN ('application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
  ) STORED,
  
  CONSTRAINT either_ticket_or_comment CHECK (
    (ticket_id IS NOT NULL AND comment_id IS NULL) OR 
    (ticket_id IS NULL AND comment_id IS NOT NULL)
  ),
  CONSTRAINT valid_size CHECK (file_size > 0 AND file_size <= 52428800) -- 50MB max
);

CREATE INDEX idx_attachments_ticket ON attachments(ticket_id);
CREATE INDEX idx_attachments_comment ON attachments(comment_id);
CREATE INDEX idx_attachments_uploaded_by ON attachments(uploaded_by_id);
```

### 2.5 Ticket History Table (Audit Trail)
```sql
CREATE TABLE ticket_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  changed_by_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  field_name VARCHAR(100) NOT NULL,
  old_value TEXT,
  new_value TEXT,
  
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ticket_history_ticket ON ticket_history(ticket_id);
CREATE INDEX idx_ticket_history_changed_at ON ticket_history(changed_at DESC);
```

---

## 3. API Endpoints Specification

### 3.1 Authentication Endpoints

#### POST `/api/v1/auth/register`
**Purpose**: Register a new user

**Request**:
```json
{
  "email": "user@example.com",
  "username": "john_doe",
  "password": "SecurePass123!@#",
  "name": "John Doe",
  "phone": "1234567890"
}
```

**Response** (201):
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "john_doe",
    "name": "John Doe",
    "role": "user",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Validation**:
- Email: valid format, unique
- Username: 3-50 chars, alphanumeric+underscore, unique
- Password: min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
- Phone: 10+ digits, numeric only

---

#### POST `/api/v1/auth/login`
**Purpose**: User login

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!@#"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "john_doe",
    "name": "John Doe",
    "role": "user",
    "profileImage": "https://cdn.example.com/avatars/uuid.jpg",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 86400
  }
}
```

**Error** (401):
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

---

#### POST `/api/v1/auth/logout`
**Purpose**: User logout

**Headers**: `Authorization: Bearer {token}`

**Response** (200):
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

#### POST `/api/v1/auth/reset-password`
**Purpose**: Send password reset email

**Request**:
```json
{
  "email": "user@example.com"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Password reset link sent to your email"
}
```

---

### 3.2 Ticket Endpoints

#### GET `/api/v1/tickets`
**Purpose**: Get all tickets (paginated, filterable)

**Headers**: `Authorization: Bearer {token}`

**Query Parameters**:
```
page=1
limit=10
status=open,in_progress,closed
priority=high,critical
search=search_term
sortBy=created_at
sortOrder=desc
```

**Response** (200):
```json
{
  "success": true,
  "data": {
    "tickets": [
      {
        "id": "uuid",
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

---

#### POST `/api/v1/tickets`
**Purpose**: Create a new ticket

**Headers**: `Authorization: Bearer {token}`

**Request**:
```json
{
  "title": "Login issue",
  "description": "Cannot login to my account",
  "category": "technical",
  "priority": "high",
  "attachments": ["file_id_1", "file_id_2"]
}
```

**Response** (201):
```json
{
  "success": true,
  "message": "Ticket created successfully",
  "data": {
    "id": "uuid",
    "title": "Login issue",
    "status": "open",
    "createdAt": "2026-04-16T10:00:00Z"
  }
}
```

---

#### GET `/api/v1/tickets/:ticketId`
**Purpose**: Get ticket details with comments

**Headers**: `Authorization: Bearer {token}`

**Response** (200):
```json
{
  "success": true,
  "data": {
    "ticket": {
      "id": "uuid",
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
          "content": "We're investigating this issue",
          "authorId": "uuid",
          "authorName": "Support Agent",
          "createdAt": "2026-04-16T10:30:00Z",
          "attachments": []
        }
      ]
    }
  }
}
```

---

#### PATCH `/api/v1/tickets/:ticketId`
**Purpose**: Update ticket (status, priority, assignment)

**Headers**: `Authorization: Bearer {token}`

**Request**:
```json
{
  "status": "in_progress",
  "priority": "high",
  "assignedToId": "uuid"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Ticket updated successfully",
  "data": {
    "id": "uuid",
    "status": "in_progress",
    "priority": "high",
    "updatedAt": "2026-04-16T12:00:00Z"
  }
}
```

---

#### DELETE `/api/v1/tickets/:ticketId`
**Purpose**: Delete a ticket (admin/creator only)

**Headers**: `Authorization: Bearer {token}`

**Response** (200):
```json
{
  "success": true,
  "message": "Ticket deleted successfully"
}
```

---

### 3.3 Comment Endpoints

#### POST `/api/v1/comments/tickets/:ticketId/comments`
**Purpose**: Add comment to ticket

**Headers**: `Authorization: Bearer {token}`

**Request**:
```json
{
  "content": "We're investigating this issue",
  "isInternal": false,
  "attachments": ["file_id_1"]
}
```

**Response** (201):
```json
{
  "success": true,
  "message": "Comment added successfully",
  "data": {
    "id": "uuid",
    "ticketId": "uuid",
    "content": "We're investigating this issue",
    "authorId": "uuid",
    "authorName": "Support Agent",
    "createdAt": "2026-04-16T10:30:00Z"
  }
}
```

---

#### DELETE `/api/v1/comments/:commentId`
**Purpose**: Delete a comment (author/admin only)

**Headers**: `Authorization: Bearer {token}`

**Response** (200):
```json
{
  "success": true,
  "message": "Comment deleted successfully"
}
```

---

### 3.4 User Endpoints

#### GET `/api/v1/users/profile`
**Purpose**: Get current user profile

**Headers**: `Authorization: Bearer {token}`

**Response** (200):
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "john_doe",
    "name": "John Doe",
    "phone": "1234567890",
    "role": "user",
    "profileImage": "https://cdn.example.com/avatars/uuid.jpg",
    "createdAt": "2026-04-16T09:00:00Z"
  }
}
```

---

#### PATCH `/api/v1/users/profile`
**Purpose**: Update user profile

**Headers**: `Authorization: Bearer {token}`

**Request**:
```json
{
  "name": "John Doe",
  "phone": "1234567890"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "uuid",
    "name": "John Doe",
    "phone": "1234567890",
    "updatedAt": "2026-04-16T12:00:00Z"
  }
}
```

---

#### POST `/api/v1/users/change-password`
**Purpose**: Change user password

**Headers**: `Authorization: Bearer {token}`

**Request**:
```json
{
  "currentPassword": "OldPass123!@#",
  "newPassword": "NewPass456!@#"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

### 3.5 File Upload Endpoint

#### POST `/api/v1/upload`
**Purpose**: Upload file (attachment)

**Headers**: 
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body**:
```
file: <binary file data>
```

**Response** (201):
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "id": "uuid",
    "fileName": "screenshot.png",
    "fileType": "image/png",
    "fileSize": 245000,
    "fileUrl": "https://cdn.example.com/attachments/uuid.png"
  }
}
```

**Constraints**:
- Max file size: 50MB
- Allowed types: images, PDFs, documents
- Scanned for viruses
- Stored in Supabase Storage

---

## 4. Authentication & Security

### 4.1 JWT Token Structure
```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "sub": "user_id_uuid",
  "email": "user@example.com",
  "role": "user",
  "iat": 1682000000,
  "exp": 1682086400,
  "iss": "e-ticketing-api"
}

Signature: HMACSHA256(base64UrlEncode(header) + "." + base64UrlEncode(payload), JWT_SECRET)
```

**Token Expiration**: 24 hours (86400 seconds)

### 4.2 Password Requirements
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character (!@#$%^&*)
- Not a common password

### 4.3 Authorization Rules
```
USER Role:
  ✓ View own tickets
  ✓ Create tickets
  ✓ Comment on own tickets
  ✓ Upload attachments to own tickets
  ✗ Assign tickets to others
  ✗ View all tickets

HELPDESK Role:
  ✓ View all tickets
  ✓ Update ticket status/priority
  ✓ Assign tickets
  ✓ Comment on any ticket
  ✓ View internal comments
  ✓ Generate reports
  ✗ Delete tickets
  ✗ Manage users

ADMIN Role:
  ✓ All permissions
  ✓ Manage users (create, update, delete)
  ✓ Delete tickets
  ✓ View audit logs
  ✓ System settings
```

---

## 5. Error Handling

### 5.1 Standard Error Response Format
```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional details"
  }
}
```

### 5.2 HTTP Status Codes
```
200 OK - Success
201 Created - Resource created
204 No Content - Success, no response body
400 Bad Request - Validation error
401 Unauthorized - Authentication required
403 Forbidden - Insufficient permissions
404 Not Found - Resource not found
409 Conflict - Resource already exists (e.g., duplicate email)
422 Unprocessable Entity - Validation failed
429 Too Many Requests - Rate limit exceeded
500 Internal Server Error - Server error
503 Service Unavailable - Service temporarily down
```

### 5.3 Common Error Codes
```
INVALID_CREDENTIALS - Login credentials incorrect
USER_NOT_FOUND - User doesn't exist
EMAIL_EXISTS - Email already registered
USERNAME_EXISTS - Username already taken
INVALID_TOKEN - JWT token invalid/expired
INSUFFICIENT_PERMISSIONS - User role lacks permission
TICKET_NOT_FOUND - Ticket doesn't exist
INVALID_FILE_SIZE - File exceeds 50MB limit
FILE_TYPE_NOT_ALLOWED - File type not supported
DATABASE_ERROR - Database operation failed
```

---

## 6. Environment Variables (.env)

```bash
# Server
NODE_ENV=development
PORT=5000
API_URL=http://localhost:5000

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
JWT_EXPIRATION=86400

# File Upload
SUPABASE_STORAGE_BUCKET=attachments
MAX_FILE_SIZE=52428800

# Email Service
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
EMAIL_FROM=support@ticketing.com

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# CORS
CORS_ORIGIN=http://localhost:5000,https://app.example.com

# Database Backup
DB_BACKUP_ENABLED=true
DB_BACKUP_INTERVAL=86400
```

---

## 7. Implementation Checklist

### Phase 1: Setup & Database (Week 1)
- [ ] Create Supabase project
- [ ] Set up PostgreSQL database
- [ ] Create all tables with migrations
- [ ] Set up Row Level Security (RLS) policies
- [ ] Configure Supabase Storage bucket

### Phase 2: Authentication (Week 1-2)
- [ ] Implement JWT token generation
- [ ] Create user registration endpoint
- [ ] Create user login endpoint
- [ ] Implement password hashing (bcrypt)
- [ ] Create authentication middleware
- [ ] Implement password reset flow

### Phase 3: Core API (Week 2-3)
- [ ] Implement ticket CRUD operations
- [ ] Implement comment endpoints
- [ ] Implement user profile endpoints
- [ ] Add pagination & filtering
- [ ] Add audit trail logging

### Phase 4: File Management (Week 3)
- [ ] Set up file upload to Supabase Storage
- [ ] Implement file validation
- [ ] Add virus scanning
- [ ] Implement file deletion

### Phase 5: Security & Testing (Week 4)
- [ ] Set up rate limiting
- [ ] Implement CORS properly
- [ ] Add request validation
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Security testing

### Phase 6: Deployment (Week 4)
- [ ] Set up CI/CD pipeline
- [ ] Deploy to production
- [ ] Set up monitoring/logging
- [ ] Configure backups

---

## 8. Rate Limiting

```
Login endpoint: 5 requests per 15 minutes per IP
Upload endpoint: 10 requests per hour per user
API endpoints: 1000 requests per hour per user
```

---

## 9. Monitoring & Logging

All API requests should log:
```json
{
  "timestamp": "2026-04-16T10:00:00Z",
  "method": "POST",
  "endpoint": "/api/v1/tickets",
  "userId": "uuid",
  "statusCode": 201,
  "duration": 125,
  "userAgent": "Flutter",
  "ipAddress": "192.168.1.1"
}
```

---

## 10. Testing Scenarios

### Authentication Tests
- [ ] Register with valid data
- [ ] Register with duplicate email
- [ ] Login with correct credentials
- [ ] Login with wrong password
- [ ] Access protected endpoint without token
- [ ] Access protected endpoint with expired token

### Ticket Tests
- [ ] Create ticket as user
- [ ] List tickets with pagination
- [ ] Filter tickets by status
- [ ] Update ticket as helpdesk
- [ ] Add comment to ticket
- [ ] Upload file to ticket

### Authorization Tests
- [ ] User cannot delete others' tickets
- [ ] User cannot assign tickets
- [ ] Helpdesk can update ticket status
- [ ] Admin can delete tickets

---

This specification provides everything needed to build a production-ready backend for your e-ticketing Flutter app!
