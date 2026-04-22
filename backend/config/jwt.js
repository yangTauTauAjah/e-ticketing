const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-key-min-32-chars-long-!!!';
const JWT_EXPIRATION = parseInt(process.env.JWT_EXPIRATION || '86400');

const generateToken = (userId, email, role) => {
  return jwt.sign(
    {
      sub: userId,
      email: email,
      role: role,
      iss: 'e-ticketing-api'
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRATION }
  );
};

const verifyToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
};

module.exports = {
  generateToken,
  verifyToken,
  JWT_SECRET,
  JWT_EXPIRATION
};
