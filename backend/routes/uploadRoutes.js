const express = require('express');
const supabase = require('../config/database');
const { authMiddleware } = require('../middleware/authMiddleware');
const { upload, getFileInfo } = require('../utils/fileUpload');
const logger = require('../utils/logger');
const Attachment = require('../models/Attachment');

const router = express.Router();

router.use(authMiddleware);

router.post('/', upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file provided',
        error: { code: 'NO_FILE' }
      });
    }

    const userId = req.user.sub;
    const fileInfo = getFileInfo(req.file);

    // Upload to Supabase Storage
    const bucketName = process.env.SUPABASE_STORAGE_BUCKET || 'attachments';
    const filePath = `${userId}/${fileInfo.fileName}`;

    const { data, error } = await supabase.storage
      .from(bucketName)
      .upload(filePath, req.file.buffer, {
        contentType: fileInfo.fileType,
        upsert: false
      });

    if (error) {
      logger.error('File upload to Supabase failed', error.message);
      return res.status(500).json({
        success: false,
        message: 'File upload failed',
        error: { code: 'UPLOAD_ERROR' }
      });
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from(bucketName)
      .getPublicUrl(filePath);

    const fileUrl = urlData.publicUrl;

    // Create attachment record
    const attachment = await Attachment.create({
      fileName: fileInfo.originalName,
      fileType: fileInfo.fileType,
      fileSize: fileInfo.fileSize,
      fileUrl,
      uploadedById: userId
    });

    logger.info('File uploaded successfully', {
      attachmentId: attachment.id,
      userId,
      fileName: fileInfo.originalName
    });

    res.status(201).json({
      success: true,
      message: 'File uploaded successfully',
      data: {
        id: attachment.id,
        fileName: attachment.file_name,
        fileType: attachment.file_type,
        fileSize: attachment.file_size,
        fileUrl: attachment.file_url
      }
    });
  } catch (error) {
    logger.error('Upload error', error.message);
    next(error);
  }
});

module.exports = router;
