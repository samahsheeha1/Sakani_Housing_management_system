// statsRoutes.js
const express = require('express');
const statsController = require('../controllers/statsController'); // Correct import path

const router = express.Router();

// Define routes for statistics
router.get('/users', statsController.getUserStats); // Correct method reference
router.get('/rooms', statsController.getRoomStats); // Correct method reference
router.get('/reservations', statsController.getReservationStats); // Correct method reference

module.exports = router;