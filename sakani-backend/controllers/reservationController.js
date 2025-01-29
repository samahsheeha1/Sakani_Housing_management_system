const Reservation = require('../models/Reservation');
const Room = require('../models/Room'); // Import Room model
const admin = require('../firebase/firebaseConfig');
const User = require('../models/User'); // Update the path to match your project structure
const Notification = require('../models/notificationModel'); // Import the Notification model
const mongoose = require('mongoose');
exports.createReservation = async (req, res) => {
  try {
    const { reservationId, roomType, roomId } = req.body;
    // Validate roomId
    if (!roomId) {
      return res.status(400).json({ message: 'roomId is required' });
    }

    // Check if the room exists
    const room = await Room.findById(roomId);
    if (!room) {
      return res.status(404).json({ message: 'Room not found' });
    }

    // Ensure the user is logged in
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    // Create a new reservation
    const newReservation = new Reservation({
      reservationId,
      roomType,
      roomId, // Save the roomId
      user: req.user.id, // Use `user` to reference the logged-in user
    });

    // Save the reservation
    const savedReservation = await newReservation.save();

    res.status(201).json(savedReservation);
  } catch (error) {
    console.error('Error saving reservation:', error);
    res.status(500).json({ message: 'Failed to save reservation' });
  }
};

// Get all reservations for the logged-in user
exports.getReservations = async (req, res) => {
  try {
    // Ensure the user is authenticated
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    // Fetch reservations for the user, populated with Room details
    const reservations = await Reservation.find({ user: req.user.id })
      .populate('roomId', 'type price availability address') // Populate Room details
      .sort({ createdAt: -1 }); // Sort by most recent

    res.status(200).json(reservations);
  } catch (error) {
    console.error('Error fetching reservations:', error);
    res.status(500).json({ message: 'Failed to fetch reservations' });
  }
};



// Fetch all reservations with pagination, search, and filtering
exports.getAllReservations = async (req, res) => {
  try {
    const { page = 1, limit = 10, status, roomType, search } = req.query;
    const userId = req.user.id; // Get user ID from token
    const role = req.user.role; // Get user role from token

    // Pagination
    const skip = (page - 1) * limit;

    // Build the query
    let query = {};
    if (status) query.status = status; // Filter by status
    if (roomType) query.roomType = roomType; // Filter by roomType
    if (search) {
      query.$or = [
        { reservationId: { $regex: search, $options: 'i' } }, // Search by reservationId
        { user: { $regex: search, $options: 'i' } }, // Search by user
      ];
    }

    // If the user is a Room Owner, fetch reservations for their rooms
    if (role === 'Room Owner') {
      // Fetch rooms owned by the Room Owner
      const rooms = await Room.find({ owner: userId });
      const roomIds = rooms.map(room => room._id);

      // Add roomIds to the query
      query.roomId = { $in: roomIds };
    }

    // Fetch reservations with pagination and filtering
    const reservations = await Reservation.find(query)
      .populate('roomId', 'type price availability address') // Populate room details
      .sort({ createdAt: -1 }) // Sort by most recent
      .skip(skip)
      .limit(parseInt(limit)); // Apply pagination

    // Count total documents for pagination metadata
    const total = await Reservation.countDocuments(query);

    res.status(200).json({
      reservations,
      total,
      currentPage: parseInt(page),
      totalPages: Math.ceil(total / limit),
    });
  } catch (error) {
    console.error('Error fetching reservations:', error);
    res.status(500).json({ message: 'Failed to fetch reservations' });
  }
};


exports.updateReservationStatus = async (req, res) => {
  try {
    const { reservationId } = req.params;
    const { status } = req.body;

    // Validate status
    if (!['Pending', 'Approved', 'Rejected'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    // Find and update the reservation
    const updatedReservation = await Reservation.findOneAndUpdate(
      { reservationId },
      { status },
      { new: true }
    );

    if (!updatedReservation) {
      return res.status(404).json({ message: 'Reservation not found' });
    }

    // Find the user associated with the reservation
    const user = await User.findById(updatedReservation.user);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    console.log('FCM Token:', user.fcmToken);

    const notificationTitle = 'Reservation Status Updated';
    const notificationMessage = `Your reservation status has been updated to ${status}.`;

    // Check if the user has an FCM token
    if (user.fcmToken) {
      // Construct the notification message
      const message = {
        notification: {
          title: notificationTitle,
          body: notificationMessage,
        },
        token: user.fcmToken, // Send notification to the user's device
      };

      // Send the notification using Firebase Admin
      try {
        await admin.messaging().send(message);
        console.log('Notification sent successfully');
      } catch (error) {
        console.error('Error sending notification:', error);
      }
    } else {
      console.warn('User does not have an FCM token');
    }

    // Save the notification to MongoDB
    const notification = new Notification({
      title: notificationTitle,
      message: notificationMessage,
      userId: user._id, // Associate the notification with the user
    });

    await notification.save(); // Save the notification in the database
    console.log('Notification saved to database');

    res.status(200).json({ message: 'Reservation status updated', updatedReservation });
  } catch (error) {
    console.error('Error updating reservation status:', error);
    res.status(500).json({ message: 'Failed to update reservation status' });
  }
};



exports.deleteReservation = async (req, res) => {
  try {
    const { reservationId } = req.params;

    // Find the reservation to be deleted
    const reservation = await Reservation.findOne({ reservationId });
    if (!reservation) {
      return res.status(404).json({ message: 'Reservation not found' });
    }

 

    // Delete the reservation
    await Reservation.deleteOne({ reservationId });

    


 

    
    res.status(200).json({ message: 'Reservation deleted successfully' });
  } catch (error) {
    console.error('Error deleting reservation:', error);
    res.status(500).json({ message: 'Failed to delete reservation' });
  }
};

exports.cancelReservation = async (req, res) => {
  try {
    const reservationId = req.params.id;

    // Find the reservation and update its status to "Canceled"
    const reservation = await Reservation.findByIdAndUpdate(
      reservationId,
      { status: 'Canceled' },
      { new: true } // Return the updated document
    );

    if (!reservation) {
      return res.status(404).json({ message: 'Reservation not found' });
    }

    res.status(200).json({ message: 'Reservation canceled successfully', reservation });
  } catch (error) {
    res.status(500).json({ message: 'Error canceling reservation', error: error.message });
  }
};


exports.getRReservations = async (req, res) => {
  try {
    const { page = 1, limit = 10, search, status, roomIds } = req.query;
    const query = {};

    console.log('Received Query Parameters:', { page, limit, search, status, roomIds });

    // Search by reservation ID or user name
    if (search) {
      query.$or = [
        { reservationId: { $regex: search, $options: 'i' } },
        { 'user.fullName': { $regex: search, $options: 'i' } },
      ];
    }

    // Filter by status
    if (status) {
      query.status = status;
    }

    // Filter by room IDs (for Room Owner)
    if (roomIds) {
      const roomIdArray = roomIds.split(',').map(id => new mongoose.Types.ObjectId(id)); // Use `new` keyword
      console.log('Room IDs (converted to ObjectId):', roomIdArray);
      query.roomId = { $in: roomIdArray };
    }

    console.log('Final Query:', JSON.stringify(query, null, 2));

    // Fetch reservations with pagination
    const reservations = await Reservation.find(query)
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .populate('user', 'fullName email phone') // Populate user details
      .populate('roomId', 'type price address') // Populate room details
      .exec();

    console.log('Fetched Reservations:', JSON.stringify(reservations, null, 2));

    // Count total reservations for pagination
    const count = await Reservation.countDocuments(query);

    res.status(200).json({
      reservations,
      currentPage: parseInt(page),
      totalPages: Math.ceil(count / limit),
    });
  } catch (error) {
    console.error('Error fetching reservations:', error);
    res.status(500).json({ message: 'Failed to fetch reservations', error: error.message });
  }
};