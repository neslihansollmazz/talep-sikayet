// middlewares/multerConfig.js

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Yükleme dizini (proje kökünde /uploads)
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Desteklenen dosya tipleri
const fileFilter = (req, file, cb) => {
  console.log('Gelen dosya tipi:', file.mimetype); 
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf' , 'image/heic' , 'image/jpg' , 'application/octet-stream', 'Image.asset', 'Image.network'];
  if (!allowedTypes.includes(file.mimetype)) {
    return cb(new Error('Yalnızca JPEG, PNG, GIF ve PDF dosyaları yüklenebilir.'));
  }
  cb(null, true);
};

// Disk Storage yapılandırması
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const extension = path.extname(file.originalname);
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9) + extension;
    cb(null, uniqueName);
  }
});

module.exports = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }  // 5MB sınır örnek
});
// Bu middleware, dosya yükleme işlemlerinde kullanılmak üzere multer'ı yapılandırır.
