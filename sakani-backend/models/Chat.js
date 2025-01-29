const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  receiverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  message: { type: String, default: '' }, // Optional since a file can exist without a text message
  fileUrl: { type: String, default: '' }, // URL to the uploaded file
  fileType: { 
    type: String, 
    enum: ['image', 'document', 'none'], 
    default: 'none' 
  }, // Type of file (image, document, or none)
  timestamp: { type: Date, default: Date.now },
  read: { type: Boolean, default: false },
  deletedFor: { type: [mongoose.Schema.Types.ObjectId], default: [] }, // Track users who deleted this chat
});

module.exports = mongoose.model('Chat', chatSchema);
