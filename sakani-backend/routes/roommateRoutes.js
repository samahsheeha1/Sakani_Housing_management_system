const express = require('express');
const {
  getAllRoommates,
  assignRoommateToUser,
  updateRoommateStatus,
} = require('../controllers/roommateController');

const router = express.Router();

// Get all roommates
router.get('/', getAllRoommates);

// Assign roommate to user
router.post('/assign', assignRoommateToUser);

// Update roommate status (Unmatch)
router.put('/:roommateId', updateRoommateStatus);

module.exports = router;
