// utils/sms.js
require('dotenv').config();
const twilio = require('twilio');

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

const smsGonder = async (telefon, mesaj) => {
  try {
    const response = await client.messages.create({
      body: mesaj,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: telefon
    });
    console.log("SMS gönderildi:", response.sid);
  } catch (error) {
    console.error("SMS gönderme hatası:", error.message);
  }
};

module.exports = smsGonder;
