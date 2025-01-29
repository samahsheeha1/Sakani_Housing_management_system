const express = require('express');
const router = express.Router();
const {getRooms,} = require('../controllers/roomController');
const roomController = require('../controllers/roomController');
const { verifyToken } = require('../middleware/authMiddleware'); // Import middleware

router.get('/', getRooms);

// Get featured rooms
router.get('/featured', roomController.getFeaturedRooms);

// Get most visited rooms
router.get('/most-visited', roomController.getMostVisitedRooms);

// Get all rooms
router.get('/all', roomController.getAllRooms);
router.get('/searchh', roomController.searchRoomss);

router.put('/:roomId/availability', roomController.updateRoomAvailability);

// Get a single room by ID
router.get('/:id', roomController.getRoomById);

// Update a room
router.put('/:id', roomController.updateRoom);

// Delete a room
router.delete('/:id', roomController.deleteRoom);

router.get('/search', roomController.searchRooms);
router.post('/', verifyToken, roomController.createRoom);

router.get('/by-owner/:ownerId', roomController.getRoomsByOwner);

module.exports = router;
