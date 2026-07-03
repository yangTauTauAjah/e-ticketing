const express = require('express');
const AuthController = require('../controllers/authController');
const { validate, schemas } = require('../middleware/validation');

const router = express.Router();

router.post('/register', validate(schemas.register), AuthController.register);
router.post('/login', validate(schemas.login), AuthController.login);
router.post('/logout', AuthController.logout);
router.post('/password-reset/request', validate(schemas.requestPasswordReset), AuthController.requestPasswordReset);
router.post('/password-reset/confirm', validate(schemas.confirmPasswordReset), AuthController.confirmPasswordReset);

module.exports = router;
