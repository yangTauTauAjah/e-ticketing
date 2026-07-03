const User = require('../models/User');
const { generateToken } = require('../config/jwt');
const logger = require('../utils/logger');
const { sendOtpEmail } = require('../utils/email');

class AuthController {
  static async register(req, res, next) {
    try {
      const { email, username, password, name, phone } = req.validatedBody;

      // Check if email or username already exists
      const existingEmail = await User.findByEmail(email);
      if (existingEmail) {
        return res.status(409).json({
          success: false,
          message: 'Email already registered',
          error: { code: 'EMAIL_EXISTS' }
        });
      }

      console.log('Checking username availability for:', username);

      const existingUsername = await User.findByUsername(username);
      if (existingUsername) {
        return res.status(409).json({
          success: false,
          message: 'Username already taken',
          error: { code: 'USERNAME_EXISTS' }
        });
      }

      // Create user
      const user = await User.create({
        email,
        username,
        password,
        name,
        phone
      });

      // Generate token
      const token = generateToken(user.id, user.email, user.role);

      logger.info('User registered', { userId: user.id, email: user.email });

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          id: user.id,
          email: user.email,
          username: user.username,
          name: user.name,
          role: user.role,
          token
        }
      });
    } catch (error) {
      logger.error('Registration error', error.message);
      next(error);
    }
  }

  static async login(req, res, next) {
    try {
      const { email, password } = req.validatedBody;

      // Find user
      const user = await User.findByEmail(email);
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials',
          error: { code: 'INVALID_CREDENTIALS' }
        });
      }

      // Verify password
      const isValidPassword = await User.verifyPassword(password, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials',
          error: { code: 'INVALID_CREDENTIALS' }
        });
      }

      // Update last login
      await User.updateLastLogin(user.id);

      // Generate token
      const token = generateToken(user.id, user.email, user.role);
      const expiresIn = parseInt(process.env.JWT_EXPIRATION || '86400');

      logger.info('User logged in', { userId: user.id, email: user.email });

      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          id: user.id,
          email: user.email,
          username: user.username,
          name: user.name,
          role: user.role,
          profileImage: user.profile_image_url,
          token,
          expiresIn
        }
      });
    } catch (error) {
      logger.error('Login error', error.message);
      next(error);
    }
  }

  static async logout(req, res, next) {
    try {
      logger.info('User logged out', { userId: req.user.sub });

      res.status(200).json({
        success: true,
        message: 'Logged out successfully'
      });
    } catch (error) {
      logger.error('Logout error', error.message);
      next(error);
    }
  }

  static async requestPasswordReset(req, res, next) {
    try {
      const { email } = req.validatedBody;

      // Check if user exists
      const user = await User.findByEmail(email);
      if (!user) {
        // Don't reveal if email exists (security)
        return res.status(200).json({
          success: true,
          message: 'If this email exists, a verification code has been sent'
        });
      }

      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      await User.setResetOtp(user.id, otp);

      try {
        await sendOtpEmail(email, otp);
      } catch (emailError) {
        logger.error('Failed to send password reset OTP email', emailError.message);
      }

      logger.info('Password reset OTP requested', { email });

      res.status(200).json({
        success: true,
        message: 'If this email exists, a verification code has been sent'
      });
    } catch (error) {
      logger.error('Password reset request error', error.message);
      next(error);
    }
  }

  static async confirmPasswordReset(req, res, next) {
    try {
      const { email, otp, newPassword } = req.validatedBody;

      const user = await User.findByEmail(email);
      if (!user) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or expired verification code',
          error: { code: 'INVALID_OTP' }
        });
      }

      const isValidOtp = await User.verifyResetOtp(user.id, otp);
      if (!isValidOtp) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or expired verification code',
          error: { code: 'INVALID_OTP' }
        });
      }

      await User.updatePassword(user.id, newPassword);
      await User.clearResetOtp(user.id);

      logger.info('Password reset via OTP', { userId: user.id });

      res.status(200).json({
        success: true,
        message: 'Password reset successfully'
      });
    } catch (error) {
      logger.error('Password reset confirm error', error.message);
      next(error);
    }
  }
}

module.exports = AuthController;
