const { verifyToken } = require('../config/jwt');
const logger = require('../utils/logger');

const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.get('authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
        error: { code: 'MISSING_TOKEN' }
      });
    }

    const token = authHeader.slice(7); // Remove 'Bearer ' prefix
    const decoded = verifyToken(token);

    if (!decoded) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token',
        error: { code: 'INVALID_TOKEN' }
      });
    }

    req.user = decoded;
    next();
  } catch (error) {
    logger.error('Auth middleware error', error.message);
    res.status(500).json({
      success: false,
      message: 'Authentication error',
      error: { code: 'AUTH_ERROR' }
    });
  }
};

const roleMiddleware = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
        error: { code: 'MISSING_TOKEN' }
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions',
        error: { code: 'INSUFFICIENT_PERMISSIONS' }
      });
    }

    next();
  };
};

module.exports = {
  authMiddleware,
  roleMiddleware
};
