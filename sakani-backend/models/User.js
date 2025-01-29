const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const UserSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String, required: false },
  address: { type: String, required: false },
  age: { type: Number, required: false }, // Age is optional
  interests: { type: [String], required: false }, // Interests are optional and stored as an array of strings
  photo: { type: String, required: false }, // Photo is optional
  resetCode: { type: Number, required: false },
  resetCodeExpiry: { type: Date, required: false },
  documents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Document' }], // Existing field for document references
   // Roommate-specific fields
  
   status: { type: String, enum: ['Matched', 'Available'], default: 'Available' },
   matchedWith: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
   role: { type: String, enum: ['Student', 'Room Owner','Admin'], required: true }, // Role is required and limited to specific values
   fcmToken: { type: String, default: null }, // Add this field

});

UserSchema.pre('save', async function (next) {
  // Skip hashing if password is not modifieds
  if (!this.isModified('password')) return next();

  // Check if the password is already hashed (using a regex for bcrypt hashes)
  const passwordRegex = /^\$2[aby]\$.{56}$/; // Matches bcrypt hashed strings
  if (passwordRegex.test(this.password)) {
    return next(); // Skip hashing if password is already hashed
  }

  // Hash the password if it is not already hashed
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

module.exports = mongoose.model('User', UserSchema);
