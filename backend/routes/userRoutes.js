const express = require('express');
const UserController = require('../controllers/userController');
const { authMiddleware } = require('../middleware/authMiddleware');
const { validate, schemas } = require('../middleware/validation');

const router = express.Router();

router.use(authMiddleware);

router.get('/profile', UserController.getProfile);
router.patch('/profile', validate(schemas.updateProfile), UserController.updateProfile);
router.post('/change-password', validate(schemas.changePassword), UserController.changePassword);

module.exports = router;
