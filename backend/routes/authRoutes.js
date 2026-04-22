const express = require('express');
const AuthController = require('../controllers/authController');
const { validate, schemas } = require('../middleware/validation');

const router = express.Router();

router.post('/register', validate(schemas.register), AuthController.register);
router.post('/login', validate(schemas.login), AuthController.login);
router.post('/logout', AuthController.logout);
router.post('/reset-password', validate(schemas.resetPassword), AuthController.resetPassword);

module.exports = router;
