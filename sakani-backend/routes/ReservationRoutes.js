const express = require('express');
const router = express.Router();
const {
  createReservation,
  getReservations,
  getAllReservations, // Import the new controller function
  updateReservationStatus, // Import the new controller function
} = require('../controllers/reservationController');
const reservationController = require('../controllers/reservationController'); // Adjust the path as needed

const { verifyToken } = require('../middleware/authMiddleware');

// Route to create a reservation
router.post('/reservations', verifyToken, createReservation);

// Route to fetch all reservations for the logged-in user
router.get('/reservations', verifyToken, getReservations);
router.get('/rreservations', reservationController.getRReservations);

// Route to fetch all reservations with pagination, search, and filtering (for admin)
router.get('/admin/reservations', verifyToken, getAllReservations); // Add this route

// Route to update the status of a reservation
router.put('/reservations/:reservationId', verifyToken, updateReservationStatus); // Add this route
router.delete('/reservations/:reservationId', reservationController.deleteReservation);
router.patch('/reservations/:id/cancel', reservationController.cancelReservation);

module.exports = router;
