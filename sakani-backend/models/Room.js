const mongoose = require('mongoose');

const RoomSchema = new mongoose.Schema({
  type: { type: String, required: true },
  price: { type: String, required: true },
  availability: { type: String, required: true },
  address: { type: String, required: true },
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
  images: { type: [String], required: true },
  beds: { type: Number, required: true }, // Number of beds in the room
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Reference to the User model
  isFeatured: { type: Boolean, default: false }, // Featured room flag
  visits: { type: Number, default: 0 }, // Track visits
});

module.exports = mongoose.model('Room', RoomSchema);