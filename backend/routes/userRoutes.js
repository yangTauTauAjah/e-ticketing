const express = require('express');
const UserController = require('../controllers/userController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');
const { validate, schemas } = require('../middleware/validation');

const router = express.Router();

router.use(authMiddleware);

router.get('/profile', UserController.getProfile);
router.patch('/profile', validate(schemas.updateProfile), UserController.updateProfile);
router.post('/change-password', validate(schemas.changePassword), UserController.changePassword);
router.get('/helpdesks', roleMiddleware(['admin']), UserController.listHelpdesks);
router.get('/', roleMiddleware(['admin']), UserController.listAll);
router.patch('/:userId/active', roleMiddleware(['admin']), UserController.setActive);
router.patch('/:userId', roleMiddleware(['admin']), validate(schemas.adminUpdateUser), UserController.adminUpdateUser);

module.exports = router;
