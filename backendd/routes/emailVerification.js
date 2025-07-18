require('dotenv').config();
const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');


const verificationCodes = {}; // { email: code }

// Kod gönderme endpoint'i
router.post('/send-code', async (req, res) => {
  const { email } = req.body;
  console.log("İstek geldi:", req.body);

  if (!email) {
    return res.status(400).json({ status: 'error', message: 'E-posta gerekli.' });
  }

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  verificationCodes[email] = code;
  console.log(`Kod ${email} için üretildi: ${code}`);


  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.MAIL_USER,
      pass: process.env.MAIL_PASS
    }
  });

  try {
    await transporter.verify();
    console.log("SMTP bağlantısı başarılı.");

    await transporter.sendMail({
      from: process.env.MAIL_USER,
      to: email,
      subject: 'Doğrulama Kodunuz',
      text: `Doğrulama kodunuz: ${code}`
    });

    console.log(`Kod e-posta ile gönderildi: ${email}`);
    res.json({ status: 'success', message: 'Kod e-posta ile gönderildi.' });
  } catch (error) {
    console.error('Mail gönderme hatası:', error);
    res.status(500).json({ status: 'error', message: 'E-posta gönderilemedi. Lütfen tekrar deneyin.' });
  }
});

// Kod doğrulama endpoint'i
router.post('/verify-code', (req, res) => {
  const { email, code } = req.body;
  console.log(`Doğrulama isteği: email=${email}, code=${code}`);

  if (!email || !code) {
    return res.status(400).json({ status: 'error', message: 'E-posta ve kod gerekli.' });
  }

  if (verificationCodes[email] === code) {
    delete verificationCodes[email];
    console.log(`Kod doğrulandı ve silindi: ${email}`);
    return res.json({ status: 'success', message: 'E-posta doğrulandı.' });
  } else {
    console.log(`Kod hatalı: ${email} için gelen ${code}, beklenen ${verificationCodes[email]}`);
    return res.status(400).json({ status: 'error', message: 'Kod hatalı veya süresi dolmuş.' });
  }
});

module.exports = {
  router,
  verificationCodes
};
