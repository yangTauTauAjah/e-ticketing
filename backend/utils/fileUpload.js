const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE) || 52428800; // 50MB

const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
];

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    return cb(new Error('File type not allowed'), false);
  }
  cb(null, true);
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: MAX_FILE_SIZE
  }
});

const getFileInfo = (file) => {
  return {
    fileName: `${uuidv4()}_${file.originalname}`,
    fileType: file.mimetype,
    fileSize: file.size,
    originalName: file.originalname
  };
};

module.exports = {
  upload,
  getFileInfo,
  ALLOWED_MIME_TYPES,
  MAX_FILE_SIZE
};
