const fs = require('fs');
const path = require('path');

const logsDir = path.join(__dirname, '../logs');

// Create logs directory if it doesn't exist
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

const levels = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3
};

const colors = {
  error: '\x1b[31m',
  warn: '\x1b[33m',
  info: '\x1b[36m',
  debug: '\x1b[35m',
  reset: '\x1b[0m'
};

const log = (level, message, data = null) => {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    ...(data && { data })
  };

  const logMessage = `[${timestamp}] [${level.toUpperCase()}] ${message}${data ? ' ' + JSON.stringify(data) : ''}`;
  
  // Console output
  console.log(
    `${colors[level]}${logMessage}${colors.reset}`
  );

  // File output
  const logFile = path.join(logsDir, `${level}.log`);
  fs.appendFileSync(logFile, JSON.stringify(logEntry) + '\n');
};

module.exports = {
  error: (message, data) => log('error', message, data),
  warn: (message, data) => log('warn', message, data),
  info: (message, data) => log('info', message, data),
  debug: (message, data) => log('debug', message, data),
  request: (req, res, duration) => {
    const logEntry = {
      timestamp: new Date().toISOString(),
      method: req.method,
      endpoint: req.path,
      userId: req.user?.id || 'anonymous',
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('user-agent'),
      ipAddress: req.ip
    };
    fs.appendFileSync(
      path.join(logsDir, 'requests.log'),
      JSON.stringify(logEntry) + '\n'
    );
  }
};
