# Backend Setup Guide - Node.js + Supabase

## Quick Start (5 minutes)

### 1. Install Node.js
Download from https://nodejs.org (LTS version 18+)

### 2. Create Backend Project
```powershell
mkdir e_ticketing_backend
cd e_ticketing_backend
npm init -y
```

### 3. Install Dependencies
```powershell
npm install express dotenv cors joi bcrypt jsonwebtoken @supabase/supabase-js multer uuid
npm install --save-dev nodemon
```

### 4. Create Supabase Project
1. Go to https://supabase.com
2. Sign up (free tier available)
3. Create new project
4. Go to Settings → API Keys
5. Copy `Project URL` and `Anon Key`

### 5. Create `.env` File
```bash
NODE_ENV=development
PORT=5000

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

JWT_SECRET=your-super-secret-key-min-32-chars-long-!!!
JWT_EXPIRATION=86400

CORS_ORIGIN=http://localhost:5000,http://localhost:8000

MAX_FILE_SIZE=52428800
```

### 6. Create `server.js`
```javascript
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'API is running' });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: { code: 'SERVER_ERROR' }
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
```

### 7. Update `package.json`
```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  }
}
```

### 8. Run Server
```powershell
npm run dev
```

Visit http://localhost:5000/api/health - should see: `{"status":"API is running"}`

---

## Database Setup in Supabase

### 1. Create Database Tables

Go to Supabase Dashboard → SQL Editor → Run this:

```sql
-- Users Table
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
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- Tickets Table
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(50) NOT NULL,
  priority VARCHAR(20) DEFAULT 'medium',
  status VARCHAR(20) DEFAULT 'open',
  created_by_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_to_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP,
  comment_count INTEGER DEFAULT 0
);

CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_created_by ON tickets(created_by_id);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to_id);

-- Comments Table
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_internal BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_comments_ticket ON comments(ticket_id);

-- Attachments Table
CREATE TABLE attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(50) NOT NULL,
  file_size INTEGER NOT NULL,
  file_url TEXT NOT NULL,
  uploaded_by_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Enable Row Level Security (RLS)

```sql
-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "users_select_own_profile" ON users
  FOR SELECT USING (auth.uid() = id);

-- Enable RLS on tickets
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Users can view their own tickets
CREATE POLICY "tickets_select_own" ON tickets
  FOR SELECT USING (created_by_id = auth.uid() OR assigned_to_id = auth.uid());
```

### 3. Create Storage Bucket

1. Go to Supabase Dashboard → Storage
2. Create bucket named `attachments`
3. Make it public
4. Set upload size limit to 50MB

---

## API Implementation Steps

### Step 1: Authentication Controller

Create `controllers/authController.js`:

```javascript
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { supabase } = require('../config/database');

const generateToken = (userId, email, role) => {
  return jwt.sign(
    { sub: userId, email, role, iat: Math.floor(Date.now() / 1000) },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRATION }
  );
};

exports.register = async (req, res) => {
  try {
    const { email, username, password, name, phone } = req.body;

    // Validation
    if (!email || !username || !password || !name) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }

    // Check if user exists
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .or(`email.eq.${email},username.eq.${username}`)
      .single();

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Email or username already exists'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const { data: newUser, error } = await supabase
      .from('users')
      .insert([{
        id: uuidv4(),
        email,
        username,
        password_hash: hashedPassword,
        name,
        phone: phone || null
      }])
      .select()
      .single();

    if (error) throw error;

    // Generate token
    const token = generateToken(newUser.id, newUser.email, newUser.role);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        id: newUser.id,
        email: newUser.email,
        username: newUser.username,
        name: newUser.name,
        role: newUser.role,
        token
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed',
      error: { code: 'REGISTRATION_ERROR' }
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password required'
      });
    }

    // Find user
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check password
    const passwordMatch = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Update last login
    await supabase
      .from('users')
      .update({ last_login: new Date().toISOString() })
      .eq('id', user.id);

    // Generate token
    const token = generateToken(user.id, user.email, user.role);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        id: user.id,
        email: user.email,
        username: user.username,
        name: user.name,
        role: user.role,
        token,
        expiresIn: parseInt(process.env.JWT_EXPIRATION)
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed'
    });
  }
};

exports.logout = (req, res) => {
  res.json({
    success: true,
    message: 'Logged out successfully'
  });
};
```

### Step 2: Authentication Middleware

Create `middleware/authMiddleware.js`:

```javascript
const jwt = require('jsonwebtoken');

exports.authenticate = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'No authentication token'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Invalid token'
    });
  }
};

exports.authorize = (roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }
    next();
  };
};
```

### Step 3: Database Config

Create `config/database.js`:

```javascript
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

module.exports = { supabase };
```

### Step 4: Routes

Create `routes/authRoutes.js`:

```javascript
const express = require('express');
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/logout', authenticate, authController.logout);

module.exports = router;
```

### Step 5: Connect Routes to Server

Update `server.js`:

```javascript
const authRoutes = require('./routes/authRoutes');

app.use('/api/v1/auth', authRoutes);
```

---

## Next Steps

1. **Implement Ticket endpoints** (CRUD operations)
2. **Implement Comment endpoints**
3. **Implement File Upload** to Supabase Storage
4. **Add Validation** using Joi
5. **Add Rate Limiting**
6. **Setup Logging**
7. **Write Tests**
8. **Deploy to Production** (Heroku, Railway, Vercel)

---

## Production Deployment

### Deploy to Railway.app (Recommended)
```powershell
npm install -g railway
railway login
railway init
railway up
```

### Deploy to Heroku
```powershell
heroku create your-app-name
git push heroku main
heroku config:set JWT_SECRET=your-secret
heroku logs --tail
```

---

## Common Issues & Solutions

### Issue: "Cannot find module '@supabase/supabase-js'"
**Solution**: `npm install @supabase/supabase-js`

### Issue: CORS errors
**Solution**: Check `.env` CORS_ORIGIN setting

### Issue: JWT token invalid
**Solution**: Ensure JWT_SECRET is long enough (min 32 chars)

### Issue: Database connection fails
**Solution**: Verify SUPABASE_URL and SUPABASE_ANON_KEY in `.env`

---

This guide gets you from zero to a working backend in 15-20 minutes!
