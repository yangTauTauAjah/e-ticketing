const logger = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
  logger.error('Unhandled error', {
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method
  });

  // Default error response
  let statusCode = 500;
  let message = 'Internal server error';
  let code = 'SERVER_ERROR';
  let details = null;

  // Handle specific error types
  if (err.name === 'ValidationError') {
    statusCode = 422;
    message = 'Validation failed';
    code = 'VALIDATION_ERROR';
    details = err.details;
  } else if (err.name === 'NotFoundError') {
    statusCode = 404;
    message = err.message;
    code = 'NOT_FOUND';
  } else if (err.name === 'UnauthorizedError') {
    statusCode = 401;
    message = err.message;
    code = 'UNAUTHORIZED';
  } else if (err.name === 'ForbiddenError') {
    statusCode = 403;
    message = err.message;
    code = 'FORBIDDEN';
  } else if (err.name === 'ConflictError') {
    statusCode = 409;
    message = err.message;
    code = 'CONFLICT';
  }

  res.status(statusCode).json({
    success: false,
    message,
    error: {
      code,
      ...(details && { details })
    }
  });
};

module.exports = errorHandler;
