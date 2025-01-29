// backend/routes/uploadRoutes.js
const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');

// Upload multiple images
router.post('/upload', upload.array('images', 10), (req, res) => {
    try {
      // Store only the relative path (e.g., "uploads/others/filename")
      const imagePaths = req.files.map((file) => `uploads/others/${file.filename}`);
  
      res.status(201).json({ imagePaths }); // Return the relative paths
    } catch (error) {
      res.status(500).json({ message: 'Error uploading images', error });
    }
  });

module.exports = router;