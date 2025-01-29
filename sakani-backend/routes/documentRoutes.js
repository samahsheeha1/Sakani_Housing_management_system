const express = require('express');
const upload = require('../middleware/upload');
const Document = require('../models/Document');
const User = require('../models/User'); // Import User model

const fs = require('fs');
const path = require('path');

const { verifyToken } = require('../middleware/authMiddleware');
const router = express.Router();
const documentController = require('../controllers/documentController');



// Route to fetch documents by user ID
router.get('/documents/:userId', documentController.getDocumentsByUserId);

router.post('/upload', verifyToken, upload.single('document'), async (req, res) => {
  try {
    console.log('File mimetype:', req.file.mimetype);
    console.log('File details:', req.file);
    const document = await Document.create({
      user: req.user.id,
      name: req.file.filename,
      path: req.file.path,
      size: req.file.size,
      mimetype: req.file.mimetype, // Store mimetype
      description: req.body.description || 'Uploaded Document',
    });
    
    // Add document ID to user's documents array
    await User.findByIdAndUpdate(
      req.user.id,
      { $push: { documents: document._id } },
      { new: true }
  );

    console.log('Document saved to database:', document);

    res.status(201).json({ message: 'Document uploaded successfully', document });
  } catch (error) {
    console.error('Error uploading document:', error);
    res.status(500).json({ message: 'Server error' });
  }
});




router.get('/list', verifyToken, async (req, res) => {
  try {
      console.log(`Fetching documents for User ID: ${req.user.id}`);
      const user = await User.findById(req.user.id).populate('documents');
      if (!user) {
          return res.status(404).json({ message: 'User not found' });
      }
      console.log('User documents:', user.documents);
      res.status(200).json(user.documents);
  } catch (error) {
      console.error('Error fetching documents:', error);
      res.status(500).json({ message: 'Server error' });
  }
});


  

router.delete('/delete/:id', verifyToken, async (req, res) => {
  try {
      const documentId = req.params.id;

      // Find the document
      const document = await Document.findById(documentId);
      if (!document) {
          return res.status(404).json({ message: 'Document not found' });
      }

      // Verify ownership
      if (document.user.toString() !== req.user.id) {
          return res.status(403).json({ message: 'Not authorized to delete this document' });
      }

      // Delete the file from the filesystem
      if (fs.existsSync(document.path)) {
          fs.unlinkSync(document.path);
          console.log(`File deleted: ${document.path}`);
      } else {
          console.warn(`File not found: ${document.path}`);
      }

      // Remove the document reference from the user's documents array
      await User.findByIdAndUpdate(req.user.id, { $pull: { documents: documentId } });

      // Delete the document from the database
      await Document.deleteOne({ _id: documentId }); // Updated to use `deleteOne`

      res.status(200).json({ message: 'Document deleted successfully' });
  } catch (error) {
      console.error('Error deleting document:', error);
      res.status(500).json({ message: 'Server error' });
  }
});





router.delete('/delete/:id', verifyToken, async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);

    if (!document || document.user.toString() !== req.user.id) {
      return res.status(404).json({ message: 'Document not found' });
    }

    // Remove the file from storage
    fs.unlink(document.path, (err) => {
      if (err) console.error('Error deleting file:', err);
    });

    // Remove the document reference from the user
    const user = await User.findById(req.user.id);
    if (user) {
      user.documents.pull(document._id);
      await user.save();
    }

    // Delete the document from the database
    await document.remove();

    res.status(200).json({ message: 'Document deleted successfully' });
  } catch (error) {
    console.error('Error deleting document:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
