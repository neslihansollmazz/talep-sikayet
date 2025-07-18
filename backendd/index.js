require('dotenv').config(); 
const express = require('express');
const cors = require('cors');
const path = require('path');
const morgan = require('morgan');

const app = express();
const port = process.env.PORT || 3000;


// Routes
const apiRoutes = require('./routes/API');
const sifreRoutes = require('./routes/passwordReset');
const uploadRoutes = require('./routes/upload');
const emailVerification = require('./routes/emailVerification');

// Middleware
app.use(morgan(':method :url :status :res[content-length] - :response-time ms'));
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Statik dosyalar
app.use(express.static(path.join(__dirname, 'proje')));
app.use(express.static(path.join(__dirname, 'form')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Route kullanımları
app.use('/api', sifreRoutes);
app.use('/api', apiRoutes);
app.use('/api', uploadRoutes);
app.use('/api/email-verification', emailVerification.router);

// Swagger
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Talep Şikayet API',
      version: '1.0.0',
      description: 'Talep Şikayet uygulaması API dökümantasyonu',
    },
    servers: [
      {
        url: `http://10.0.2.2:${port}`,
      },
    ],
  },
  apis: [path.join(__dirname, 'routes/*.js')],
};
const swaggerSpec = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Basit test
app.get('/', (req, res) => {
  res.status(200).send({ message: 'Merhaba, bu bir Node.js uygulamasıdır!' });
});

// Hata yakalayıcı
app.use((err, req, res, next) => {
  console.error("HATA:", err.stack);
  res.status(500).json({ status: 'error', message: 'Sunucu hatası!' });
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('UNHANDLED REJECTION:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('UNCAUGHT EXCEPTION:', err);
});

// Sunucuyu başlat
app.listen(port, () => {
  console.log(`🚀 Sunucu http://localhost:${port} üzerinde çalışıyor`);
});

app.use((err, req, res, next) => {
  console.error('Hata:', err.stack);
  res.status(500).json({ error: 'Internal Server Error', detail: err.message });
});