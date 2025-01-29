const mongoose = require('mongoose');

const DocumentSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  path: { type: String, required: true },
  size: { type: Number, required: true }, // File size in bytes
  mimetype: { type: String, required: true }, 
  uploadDate: { type: Date, default: Date.now },
  description: { type: String, default: '' }, // e.g., "ID Proof", "Registration Proof"
});

module.exports = mongoose.model('Document', DocumentSchema);


