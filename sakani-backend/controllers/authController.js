const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');
const Chat = require('../models/Chat');
const mongoose = require('mongoose');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

const multer = require('multer');
const upload = multer({ dest: 'uploads/' });

exports.registerUser = async (req, res) => {
  console.log('Received request body:', req.body); // Debug log: Log the entire request body
  console.log('Uploaded file:', req.file); // Debug log: Log the uploaded file

  const { fullName, email, password, phone, address, age, role } = req.body;
  let interests = [];

  try {
    // Check if the user already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Validate role
    if (!role || (role !== 'Student' && role !== 'Room Owner')) {
      return res.status(400).json({ message: 'Invalid role provided' });
    }

    // Parse interests for Student role
    if (role === 'Student') {
      if (!req.body.interests) {
        return res.status(400).json({ message: 'Interests are required for students' });
      }

      try {
        interests = JSON.parse(req.body.interests); // Parse the JSON string
        console.log('Parsed interests:', interests); // Debug log: Log the parsed interests
      } catch (error) {
        console.error('Error parsing interests:', error);
        return res.status(400).json({ message: 'Invalid interests format' });
      }

      if (!Array.isArray(interests) || interests.length === 0) {
        return res.status(400).json({ message: 'Interests are required for students' });
      }
    }

    // Validate that interests are not provided for Room Owner role
    if (role === 'Room Owner' && req.body.interests) {
      return res.status(400).json({ message: 'Room owners should not provide interests' });
    }

    // Get the uploaded photo file path
    const photoPath = req.file ? req.file.path : null;
    console.log('Photo path:', photoPath); // Debug log: Log the photo path

    // Create the user
    const user = await User.create({
      fullName,
      email,
      password,
      phone,
      address,
      age,
      interests: role === 'Student' ? interests : undefined,
      photo: photoPath,
      role,
    });

    if (user) {
      res.status(201).json({
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        photo: user.photo,
        token: generateToken(user._id),
      });
    } else {
      res.status(400).json({ message: 'Invalid user data' });
    }
  } catch (error) {
    console.error('Error in registerUser:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.loginUser = async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (user && (await bcrypt.compare(password, user.password))) {
      res.status(200).json({
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        token: generateToken(user._id),
      });
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};


// Send reset code email
const sendResetCodeEmail = async (email, resetCode) => {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Password Reset Code',
    text: `To reset your password, use this code: ${resetCode}. The code will expire in 10 minutes.`,
  };

  await transporter.sendMail(mailOptions);
};

// Forgot password (send reset code)
exports.forgotPassword = async (req, res) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Generate reset code (6-digit code)
    const resetCode = Math.floor(100000 + Math.random() * 900000);  // Generates a 6-digit code
    user.resetCode = resetCode;
    user.resetCodeExpiry = Date.now() + 600000;  // Code expires in 10 minutes
    await user.save();

    // Send reset code email
    await sendResetCodeEmail(email, resetCode);
    res.status(200).json({ message: 'Password reset code sent' });

  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

exports.resetPasswordConfirmation = async (req, res) => {
  const { email, resetCode } = req.body;

  console.log('Request Body:', req.body); // Debugging

  try {
    const user = await User.findOne({
      email: email,
      resetCode: parseInt(resetCode),
      resetCodeExpiry: { $gt: Date.now() }, // Ensure the code is not expired
    });

    if (!user) {
      console.log('User not found or invalid code');
      return res.status(400).json({ message: 'Invalid or expired reset code' });
    }

    res.status(200).json({ message: 'Code verified, you can reset your password' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.resetPassword = async (req, res) => {
  const { resetCode, newPassword, confirmPassword, email } = req.body;
  try {
    const user = await User.findOne({
      email,
      resetCode: parseInt(resetCode),
      resetCodeExpiry: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired reset code' });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({ message: 'Passwords do not match' });
    }

    // Hash the new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    console.log('New hashed password:', hashedPassword);

    user.password = hashedPassword;
    user.resetCode = undefined; // Clear the reset code
    user.resetCodeExpiry = undefined; // Clear the reset code expiry

    // Save the user
    const savedUser = await user.save();
    console.log('Saved user:', savedUser);

    res.status(200).json({ message: 'Password successfully updated' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.changePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const userId = req.user.id; // Ensure middleware sets req.user

  try {
    // Validate input
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Both current and new passwords are required' });
    }

    // Find the user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Verify current password
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    // Update password
    user.password = hashedPassword;
    await user.save();

    console.log('Password updated for user:', user);

    res.status(200).json({ message: 'Password updated successfully' });
  } catch (error) {
    console.error('Error in changePassword:', error);
    res.status(500).json({ message: 'Server error' });
  }
};





// Add a student
exports.addStudent = async (req, res) => {
  try {
    const { fullName, email, password, phone, address, age, interests, photo } = req.body;

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10); // 10 is the salt rounds

    const newStudent = new User({
      fullName,
      email,
      password: hashedPassword, // Save the hashed password
      phone,
      address,
      age,
      interests,
      photo, // Add the photo field
      role: 'Student',
    });

    await newStudent.save();
    res.status(201).json({ message: 'Student added successfully', student: newStudent });
  } catch (error) {
    res.status(500).json({ message: 'Error adding student', error: error.message });
  }
};

// Edit a student
exports.editStudent = async (req, res) => {
  try {
    const { id } = req.params;
    const { fullName, email, password, phone, address, age, interests } = req.body;

    // Find the student
    const student = await User.findById(id);
    if (!student) {
      return res.status(404).json({ message: 'Student not found' });
    }

    // Update fields
    student.fullName = fullName;
    student.email = email;
    student.phone = phone;
    student.address = address;
    student.age = age;
    student.interests = interests;

    // Hash the new password if it's provided
    if (password) {
      const hashedPassword = await bcrypt.hash(password, 10); // Hash the new password
      student.password = hashedPassword;
    }

    await student.save();
    res.status(200).json({ message: 'Student updated successfully', student });
  } catch (error) {
    res.status(500).json({ message: 'Error updating student', error: error.message });
  }
};

// Get all students
exports.getAllStudents = async (req, res) => {
  try {
    const students = await User.find({ role: 'Student' }).populate('documents');
    res.status(200).json(students);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching students', error: error.message });
  }
};

// Reset password
exports.resetPasswordd = async (req, res) => {
  try {
    const { id } = req.params;
    const { resetCode, newPassword } = req.body;

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: 'Student not found' });
    }

    if (user.resetCode !== resetCode || user.resetCodeExpiry < Date.now()) {
      return res.status(400).json({ message: 'Invalid or expired reset code' });
    }

    user.password = newPassword;
    user.resetCode = null; // Clear the reset code
    user.resetCodeExpiry = null; // Clear the expiry
    await user.save();

    res.status(200).json({ message: 'Password reset successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error resetting password', error: error.message });
  }
};

// Assign roommate
exports.assignRoommate = async (req, res) => {
  try {
    const { studentId, roommateId } = req.body;

    const student = await User.findById(studentId);
    const roommate = await User.findById(roommateId);

    if (!student || !roommate) {
      return res.status(404).json({ message: 'Student or roommate not found' });
    }

    student.matchedWith = roommateId;
    student.status = 'Matched';
    roommate.matchedWith = studentId;
    roommate.status = 'Matched';

    await student.save();
    await roommate.save();

    res.status(200).json({ message: 'Roommates assigned successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error assigning roommates', error: error.message });
  }
};

exports.getUserDetails = async (req, res) => {
  try {
    const userId = req.params.userId;

    // Check if userId is a valid ObjectId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    // Find the user by ID
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Return the user details
    res.status(200).json(user);
  } catch (error) {
    console.error('Error fetching user details:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
  }
};


// Fetch all room owners with role "Room Owner"
exports.getAllRoomOwners = async (req, res) => {
  try {
    const roomOwners = await User.find({ role: "Room Owner" }); // Filter by role
    res.status(200).json(roomOwners);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update a room owner
exports.updateRoomOwner = async (req, res) => {
  const { id } = req.params;
  try {
    const updatedRoomOwner = await User.findByIdAndUpdate(id, req.body, { new: true });
    res.status(200).json(updatedRoomOwner);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete a room owner
exports.deleteRoomOwner = async (req, res) => {
  const { id } = req.params;
  try {
    await User.findByIdAndDelete(id);
    res.status(200).json({ message: 'Room owner deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all users who have chatted with a specific user, including unread message status
exports.getUsersWhoChattedWithUser = async (req, res) => {
  const { userId } = req.params;
  try {
    // Find all chats where the user is either the sender or receiver
    const chats = await Chat.find({
      $or: [{ senderId: userId }, { receiverId: userId }],
    });

    // Extract unique user IDs from the chats
    const userIds = [
      ...new Set(
        chats.flatMap((chat) => [chat.senderId.toString(), chat.receiverId.toString()])
      ),
    ].filter((id) => id !== userId); // Exclude the current user's ID

    // Fetch user details for these IDs
    const users = await User.find({ _id: { $in: userIds } }).select(
      '_id fullName photo role'
    );

    // Add unread message status for each user
    const usersWithUnreadStatus = await Promise.all(
      users.map(async (user) => {
        const unreadMessages = await Chat.countDocuments({
          $or: [
            { senderId: user._id, receiverId: userId, read: false }, // Messages sent to the admin
            { senderId: userId, receiverId: user._id, read: false }, // Messages sent by the admin
          ],
        });
        return {
          ...user.toObject(),
          hasUnreadMessages: unreadMessages > 0,
        };
      })
    );

    res.status(200).json(usersWithUnreadStatus);
  } catch (error) {
    console.error('Error fetching user chats:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
