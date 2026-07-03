const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

async function sendPasswordResetEmail(toEmail, resetLink) {
  await transporter.sendMail({
    from: process.env.SMTP_FROM || 'noreply@e-ticketing.app',
    to: toEmail,
    subject: 'E-Ticketing — Password Reset Request',
    html: `
      <h2>Password Reset</h2>
      <p>You requested a password reset for your E-Ticketing account.</p>
      <p>Use the link below to reset your password. The link is valid for 1 hour.</p>
      <a href="${resetLink}" style="padding:12px 24px;background:#0F172A;color:white;text-decoration:none;border-radius:8px;">
        Reset Password
      </a>
      <p>If you did not request this, ignore this email.</p>
    `
  });
}

module.exports = { sendPasswordResetEmail };
