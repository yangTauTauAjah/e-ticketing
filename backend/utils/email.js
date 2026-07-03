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

async function sendOtpEmail(toEmail, otp) {
  await transporter.sendMail({
    from: process.env.SMTP_FROM || 'noreply@e-ticketing.app',
    to: toEmail,
    subject: 'E-Ticketing — Password Reset Verification Code',
    html: `
      <h2>Password Reset Verification Code</h2>
      <p>Use the code below to reset your E-Ticketing password. This code is valid for 10 minutes.</p>
      <p style="font-size:32px;font-weight:bold;letter-spacing:8px;">${otp}</p>
      <p>If you did not request this, ignore this email.</p>
    `
  });
}

module.exports = { sendOtpEmail };
