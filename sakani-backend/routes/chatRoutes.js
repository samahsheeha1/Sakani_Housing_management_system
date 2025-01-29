const express = require('express');
const { 
  getMessages, 
  deleteChat, 
  markAsRead, 
  uploadFileAndSaveMessage 
   // Import the new controller function
} = require('../controllers/chatController');
const upload = require('../middleware/upload'); // Import the multer middleware
const router = express.Router();
const chatController = require('../controllers/chatController');

// Endpoint to fetch chat history between two users
router.get('/:userId/:roommateId', getMessages);

// Endpoint to delete chat for the user
router.post('/delete-chat', deleteChat);

// Endpoint to mark messages as read
router.post('/mark-as-read', markAsRead);

// Endpoint to upload a file and save the message
router.post('/upload-file', upload.single('file'), uploadFileAndSaveMessage);


module.exports = router;
