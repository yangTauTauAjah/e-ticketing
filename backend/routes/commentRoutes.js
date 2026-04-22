const express = require('express');
const CommentController = require('../controllers/commentController');
const { authMiddleware } = require('../middleware/authMiddleware');
const { validate, schemas } = require('../middleware/validation');

const router = express.Router();

router.use(authMiddleware);

router.post('/tickets/:ticketId/comments', validate(schemas.createComment), CommentController.create);
router.delete('/:commentId', CommentController.delete);

module.exports = router;
