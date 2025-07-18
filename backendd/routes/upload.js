const express = require('express');
const router = express.Router();
const upload = require('../middleware/multerConfig');

router.post('/single', upload.single('dosya'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ status: "error", message: "Dosya yüklenemedi." });
  }

  const parts = req.file.path.replace(/\\/g, '/').split('/');
  const filename = parts[parts.length - 1];
  const publicUrl = `http://localhost:3000/uploads/${filename}`;

  return res.json({
    status: "success",
    message: "Dosya başarıyla yüklendi.",
    path: publicUrl
  });
});

module.exports = router;
