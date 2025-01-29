// statsController.js
const User = require('../models/User');
const Room = require('../models/Room');
const Reservation = require('../models/Reservation');

// Fetch user statistics
const getUserStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const matchedUsers = await User.countDocuments({ status: 'Matched' });
    const availableUsers = await User.countDocuments({ status: 'Available' });
    const students = await User.countDocuments({ role: 'Student' });
    const roomOwners = await User.countDocuments({ role: 'Room Owner' });
    const admins = await User.countDocuments({ role: 'Admin' });

    res.status(200).json({
      success: true,
      data: {
        totalUsers,
        matchedUsers,
        availableUsers,
        students,
        roomOwners,
        admins,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user statistics',
      error: error.message,
    });
  }
};

// Fetch room statistics
const getRoomStats = async (req, res) => {
  try {
    const totalRooms = await Room.countDocuments();
    const availableRooms = await Room.countDocuments({ availability: 'Available' });
    const occupiedRooms = await Room.countDocuments({ availability: 'Fully Booked' });
    const roomTypes = await Room.aggregate([
      { $group: { _id: '$type', count: { $sum: 1 } } },
    ]);

    res.status(200).json({
      success: true,
      data: {
        totalRooms,
        availableRooms,
        occupiedRooms,
        roomTypes,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching room statistics',
      error: error.message,
    });
  }
};

// Fetch reservation statistics
const getReservationStats = async (req, res) => {
  try {
    const totalReservations = await Reservation.countDocuments();
    const pendingReservations = await Reservation.countDocuments({ status: 'Pending' });
    const confirmedReservations = await Reservation.countDocuments({ status: 'Approved' });
    const canceledReservations = await Reservation.countDocuments({ status: 'Canceled' });

    res.status(200).json({
      success: true,
      data: {
        totalReservations,
        pendingReservations,
        confirmedReservations,
        canceledReservations,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching reservation statistics',
      error: error.message,
    });
  }
};

// Export the methods
module.exports = {
  getUserStats,
  getRoomStats,
  getReservationStats,
};