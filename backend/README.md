# E-Ticketing Backend API

A production-ready Node.js + Express + Supabase backend for an e-ticketing helpdesk system.

## Features

✅ **Authentication & Security**
- JWT-based authentication
- Password hashing with bcrypt
- Role-based access control (User, Helpdesk, Admin)
- Request validation

✅ **Ticket Management**
- Create, read, update, delete tickets
- Ticket categorization and priority levels
- Status tracking (open, assigned, in_progress, closed, reopened)
- Ticket assignment to support staff
- Comment count tracking

✅ **Comments & Collaboration**
- Add comments to tickets
- Internal comments (visible only to staff)
- Delete comments (author or admin only)
- Comment tracking

✅ **File Management**
- Upload attachments to tickets and comments
- Supabase Storage integration
- File type validation (images, PDFs, documents)
- 50MB file size limit per file

✅ **User Management**
- User registration and login
- Profile management
- Password change functionality
- Last login tracking

✅ **Audit & Logging**
- Request logging
- Error logging
- Ticket history tracking
- Colored console output

## Technology Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js 4.x
- **Database**: Supabase (PostgreSQL 15+)
- **Authentication**: JWT (jsonwebtoken)
- **Password Hashing**: bcrypt
- **Validation**: Joi
- **File Upload**: multer
- **Logging**: Custom logger
- **CORS**: cors package

## Project Structure

```
backend/
├── config/                 # Configuration files
│   ├── database.js        # Supabase connection
│   ├── jwt.js             # JWT token generation/verification
│   └── environment.js     # Environment variables
├── controllers/           # Business logic
│   ├── authController.js
│   ├── ticketController.js
│   ├── commentController.js
│   └── userController.js
├── models/               # Data models
│   ├── User.js
│   ├── Ticket.js
│   ├── Comment.js
│   └── Attachment.js
├── routes/              # API routes
│   ├── authRoutes.js
│   ├── ticketRoutes.js
│   ├── commentRoutes.js
│   ├── userRoutes.js
│   └── uploadRoutes.js
├── middleware/          # Express middleware
│   ├── authMiddleware.js
│   ├── errorHandler.js
│   └── validation.js
├── utils/              # Utility functions
│   ├── logger.js
│   └── fileUpload.js
├── migrations/         # Database schema
│   └── init.sql
├── logs/              # Log files (created at runtime)
├── .env               # Environment variables
├── .env.example       # Environment template
├── server.js          # Entry point
└── package.json       # Dependencies
```

## Setup Instructions

### 1. Clone & Install Dependencies

```bash
npm install
```

### 2. Set up Supabase

1. Create a Supabase project at https://supabase.com
2. Go to Project Settings → API
3. Copy your project URL and service role key
4. Run the migration SQL in `migrations/init.sql` in Supabase SQL Editor
5. Set up a storage bucket named "attachments" in Supabase Storage

### 3. Configure Environment Variables

```bash
cp .env.example .env
```

Update `.env` with your Supabase credentials and other settings:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
JWT_SECRET=your-secret-key-min-32-chars
```

### 4. Run the Server

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

The API will be available at `http://localhost:5000`

## API Endpoints

### Authentication

- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/logout` - User logout
- `POST /api/v1/auth/reset-password` - Request password reset

### Tickets

- `GET /api/v1/tickets` - List tickets (paginated)
- `POST /api/v1/tickets` - Create ticket
- `GET /api/v1/tickets/:ticketId` - Get ticket details
- `PATCH /api/v1/tickets/:ticketId` - Update ticket
- `DELETE /api/v1/tickets/:ticketId` - Delete ticket

### Comments

- `POST /api/v1/comments/tickets/:ticketId/comments` - Add comment
- `DELETE /api/v1/comments/:commentId` - Delete comment

### Users

- `GET /api/v1/users/profile` - Get user profile
- `PATCH /api/v1/users/profile` - Update profile
- `POST /api/v1/users/change-password` - Change password

### File Upload

- `POST /api/v1/upload` - Upload file attachment

## Authentication

All protected endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer {token}
```

### Token Structure

```json
{
  "sub": "user_uuid",
  "email": "user@example.com",
  "role": "user",
  "iat": 1682000000,
  "exp": 1682086400,
  "iss": "e-ticketing-api"
}
```

**Expiration**: 24 hours

## Authorization Rules

### User Role
- ✓ Create own tickets
- ✓ View own tickets
- ✓ Comment on own tickets
- ✓ Upload attachments
- ✗ View all tickets
- ✗ Assign tickets
- ✗ Delete tickets

### Helpdesk Role
- ✓ View all tickets
- ✓ Update ticket status/priority
- ✓ Assign tickets to users
- ✓ View internal comments
- ✓ Comment on any ticket
- ✗ Delete tickets
- ✗ Manage users

### Admin Role
- ✓ All permissions
- ✓ Manage users
- ✓ Delete tickets
- ✓ View audit logs

## Error Handling

All errors follow this format:

```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "details": {}
  }
}
```

### Common Error Codes

- `INVALID_CREDENTIALS` - Login failed
- `USER_NOT_FOUND` - User doesn't exist
- `EMAIL_EXISTS` - Email already registered
- `USERNAME_EXISTS` - Username taken
- `INVALID_TOKEN` - JWT invalid/expired
- `INSUFFICIENT_PERMISSIONS` - User lacks permission
- `TICKET_NOT_FOUND` - Ticket not found
- `VALIDATION_ERROR` - Request validation failed
- `FILE_TYPE_NOT_ALLOWED` - Unsupported file type

### HTTP Status Codes

- `200` - Success
- `201` - Resource created
- `400` - Bad request / Validation error
- `401` - Unauthorized / Invalid credentials
- `403` - Forbidden / Insufficient permissions
- `404` - Resource not found
- `409` - Conflict / Resource exists
- `422` - Validation failed
- `500` - Internal server error

## Validation Rules

### Registration
- **Email**: Valid format, unique
- **Username**: 3-50 chars, alphanumeric + underscore, unique
- **Password**: Min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
- **Name**: Max 255 chars
- **Phone**: 10+ digits (optional)

### Ticket Creation
- **Title**: 5-255 chars
- **Description**: Min 10 chars
- **Category**: billing, technical, account, general, feature_request
- **Priority**: low, medium, high, critical (default: medium)

### File Upload
- **Max Size**: 50MB
- **Allowed Types**: Images (JPEG, PNG, GIF, WebP), PDF, Word, Excel

## Logging

Logs are stored in the `logs/` directory:

- `error.log` - Error messages
- `warn.log` - Warnings
- `info.log` - Info messages
- `debug.log` - Debug messages
- `requests.log` - API request logs

Each log entry includes:
- Timestamp
- Log level
- Message
- Additional data (if applicable)

## Development

### Running in Development Mode

```bash
npm run dev
```

This uses nodemon for automatic server restart on file changes.

### Environment Setup for Development

```bash
NODE_ENV=development
PORT=5000
```

## Database Migrations

To set up the database:

1. Open Supabase SQL Editor
2. Copy the content from `migrations/init.sql`
3. Execute the SQL to create all tables and indexes

The migration includes:
- Users table with validation constraints
- Tickets table with status and priority
- Comments table with internal flag
- Attachments table with file validation
- Ticket history table for audit trail

## Security Features

✅ **Password Security**
- Passwords hashed with bcrypt (salt rounds: 10)
- Minimum requirements enforced
- Never stored in plain text

✅ **JWT Security**
- Signed with strong secret key
- 24-hour expiration
- Token issued per session

✅ **Authorization**
- Role-based access control
- Resource-level permissions
- User isolation (users see own tickets only)

✅ **Input Validation**
- Joi schema validation
- Email format validation
- File type restrictions
- File size limits

✅ **CORS Protection**
- Configurable allowed origins
- Credentials support

## API Usage Examples

### Register User

```bash
curl -X POST http://localhost:5000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "username": "john_doe",
    "password": "SecurePass123!@#",
    "name": "John Doe",
    "phone": "1234567890"
  }'
```

### Login

```bash
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!@#"
  }'
```

### Create Ticket

```bash
curl -X POST http://localhost:5000/api/v1/tickets \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Login issue",
    "description": "Cannot login to my account",
    "category": "technical",
    "priority": "high"
  }'
```

### Upload File

```bash
curl -X POST http://localhost:5000/api/v1/upload \
  -H "Authorization: Bearer {token}" \
  -F "file=@screenshot.png"
```

## Performance Considerations

- **Pagination**: Default 10 items per page
- **Indexes**: Created on frequently queried columns
- **Connection Pooling**: Managed by Supabase
- **File Storage**: Supabase Storage (CDN enabled)

## Future Enhancements

- [ ] Email notifications
- [ ] Real-time updates (WebSocket)
- [ ] Advanced filtering and search
- [ ] Ticket templates
- [ ] SLA management
- [ ] Knowledge base integration
- [ ] Customer satisfaction surveys
- [ ] Advanced analytics

## Troubleshooting

### "Cannot connect to Supabase"
- Check SUPABASE_URL and credentials in .env
- Verify Supabase project is active
- Check network connectivity

### "JWT token invalid"
- Ensure JWT_SECRET is set correctly
- Check token hasn't expired (24 hours)
- Verify Authorization header format: "Bearer {token}"

### "File upload failed"
- Check file size (max 50MB)
- Verify file type is allowed
- Ensure Supabase Storage bucket exists
- Check storage quota

## Support & Documentation

For more information, see:
- [Supabase Documentation](https://supabase.com/docs)
- [Express.js Guide](https://expressjs.com/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)
- [OWASP Security Best Practices](https://owasp.org/)

## License

ISC

## Author

Your Name / Your Team
