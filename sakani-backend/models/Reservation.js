const mongoose = require('mongoose');

const ReservationSchema = new mongoose.Schema({
  reservationId: { type: String, required: true },
  roomType: { type: String, required: true },
  roomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Room', required: true }, // Reference the Room collection
  status: { type: String, default: 'Pending' },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Reservation', ReservationSchema);
