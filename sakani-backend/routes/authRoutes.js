const express = require('express');
const User = require('../models/User'); // Import User model
const { verifyToken } = require('../middleware/authMiddleware'); // Import middleware
const { registerUser, loginUser, forgotPassword, resetPasswordConfirmation, resetPassword, changePassword} = require('../controllers/authController');
const router = express.Router();
const upload = require('../middleware/upload');
const userController = require('../controllers/authController');

const {
  getAllStudents,
  addStudent,
  editStudent,
  resetPasswordd,
  assignRoommate,
} = require('../controllers/authController');


router.put('/update-profile', verifyToken, async (req, res) => {
  const { fullName, email, phone, address } = req.body;

  // Validate request body
  if (!fullName || !email) {
    return res.status(400).json({ message: 'Full name and email are required' });
  }

  try {
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { fullName, email, phone, address },
      { new: true } // Return the updated document
    ).select('-password'); // Exclude the password field

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json(user);
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.get('/', getAllStudents);
router.post('/', addStudent);
router.put('/:id', editStudent);
router.post('/reset-password/:id', resetPasswordd);
router.post('/assign-roommate', assignRoommate);
router.get('/details/:userId', userController.getUserDetails); 
router.post('/register', upload.single('photo'), registerUser);
router.post('/login', loginUser);

router.get('/room-owners', userController.getAllRoomOwners);
router.put('/room-owners/:id', userController.updateRoomOwner);
router.delete('/room-owners/:id', userController.deleteRoomOwner);

router.post('/forgot-password', forgotPassword);
router.post('/reset-password-confirmation', resetPasswordConfirmation);
router.post('/reset-password', resetPassword);
router.post('/change-password', verifyToken, changePassword);
router.get('/:userId/chats',userController.getUsersWhoChattedWithUser);


router.get('/profile', verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password'); // Exclude the password field
    if (user) {
      return res.status(200).json(user);
    } else {
      return res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    return res.status(500).json({ message: 'Server error' });
  }
});






router.post('/save-token', async (req, res) => {
  const { userId, fcmToken } = req.body;

  if (!userId || !fcmToken) {
    return res.status(400).json({ message: 'userId and fcmToken are required' });
  }
  console.log('userId:', userId);
  console.log('fcmToken:', fcmToken);
  try {
    // Update the user with the new FCM token
    const user = await User.findByIdAndUpdate(
      userId,
      { fcmToken },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ message: 'FCM Token saved successfully' });
  } catch (error) {
    console.error('Error saving FCM Token:', error);
    res.status(500).json({ message: 'Failed to save FCM Token', error });
  }
});




// Fetch admin details
router.get('/details', async (req, res) => {
  try {
    const admin = await User.findOne({ role: 'Admin' });
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }

    res.json({
      id: admin._id,
      name: admin.fullName, // Assuming the admin's name is stored in `fullName`
    });
  } catch (err) { res.status(500).json({ message: 'Server error' });
}
});
   
module.exports = router;
