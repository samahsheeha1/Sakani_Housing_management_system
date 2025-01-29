const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { verifyToken } = require('../middleware/authMiddleware'); // Import middleware

router.post('/', notificationController.sendNotification); // Send notification
router.post('/subscribe', notificationController.subscribeToGeneralTopic); // Subscribe to general topic
router.get('/:id', notificationController.getNotifications); // Fetch notifications for a user


router.get('/notifications/unread/:userId', notificationController.getUnreadNotifications);
router.put('/notifications/mark-read/:notificationId', notificationController.markNotificationAsRead);

module.exports = router;
