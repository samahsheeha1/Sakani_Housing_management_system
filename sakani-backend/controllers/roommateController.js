const Roommate = require('../models/User');

// Fetch all roommates
const getAllRoommates = async (req, res) => {
  try {
    const roommates = await Roommate.find();
    res.status(200).json(roommates);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching roommates', error });
  }
};

// Assign a roommate to a user
const assignRoommateToUser = async (req, res) => {
  const { roommateId, userId } = req.body;

  try {
    const roommate = await Roommate.findById(roommateId);

    if (!roommate) {
      return res.status(404).json({ message: 'Roommate not found' });
    }

    if (roommate.status === 'Matched') {
      return res.status(400).json({ message: 'Roommate is already matched' });
    }

    roommate.status = 'Matched';
    roommate.matchedWith = userId;
    await roommate.save();

    res.status(200).json({ message: 'Roommate assigned successfully', roommate });
  } catch (error) {
    res.status(500).json({ message: 'Error assigning roommate', error });
  }
};

// Update roommate status (unmatch)
const updateRoommateStatus = async (req, res) => {
  const { roommateId } = req.params;
  const { status } = req.body;

  try {
    const roommate = await Roommate.findByIdAndUpdate(
      roommateId,
      { status, matchedWith: status === 'Available' ? null : undefined },
      { new: true }
    );

    if (!roommate) {
      return res.status(404).json({ message: 'Roommate not found' });
    }

    res.status(200).json({ message: 'Roommate status updated', roommate });
  } catch (error) {
    res.status(500).json({ message: 'Error updating roommate status', error });
  }
};

module.exports = {
  getAllRoommates,
  assignRoommateToUser,
  updateRoommateStatus,
};
