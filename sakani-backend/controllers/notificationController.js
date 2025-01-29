const admin = require('../firebase/firebaseConfig');
const Notification = require('../models/notificationModel');

exports.sendNotification = async (req, res) => {
  const { title, message, userId, fcmToken } = req.body;

  try {
      if (!userId) {
          // General notification
          const payload = {
              notification: { title, body: message },
          };
          await admin.messaging().sendToTopic('general', payload); // Send to general topic
          res.status(200).json({ message: 'General notification sent successfully' });
      } else {
          // User-specific notification
          const payload = {
              notification: { title, body: message },
          };
          await admin.messaging().sendToDevice(fcmToken, payload); // Send to specific user
          res.status(200).json({ message: 'Notification sent to user successfully' });
      }
  } catch (error) {
      res.status(500).json({ message: 'Error sending notification', error });
  }
};



exports.subscribeToGeneralTopic = async (req, res) => {
  const { fcmToken } = req.body;

  try {
      await admin.messaging().subscribeToTopic(fcmToken, 'general');
      res.status(200).json({ message: 'Subscribed to general topic successfully' });
  } catch (error) {
      res.status(500).json({ message: 'Error subscribing to general topic', error });
  }
};

exports.getNotifications = async (req, res) => {
  try {
      const userId = req.params.id;
      const notifications = await Notification.find({ 
          $or: [
              { userId: userId },
              { isGeneral: true }
          ]
      }).sort({ createdAt: -1 });

      res.status(200).json(notifications);
  } catch (error) {
      res.status(500).json({ message: error.message });
  }
};


exports.getUnreadNotifications = async (req, res) => {
    try {
        const { userId } = req.params;

        const notifications = await Notification.find({
            userId,
            read: false,
        }).sort({ createdAt: -1 });

        res.status(200).json(notifications);
    } catch (error) {
        res.status(500).json({ message: 'Failed to fetch notifications', error });
    }
};

/**
 * Mark a notification as read.
 */
exports.markNotificationAsRead = async (req, res) => {
    try {
        const { notificationId } = req.params;

        const notification = await Notification.findByIdAndUpdate(
            notificationId,
            { read: true },
            { new: true },
        );

        if (!notification) {
            return res.status(404).json({ message: 'Notification not found' });
        }

        res.status(200).json(notification);
    } catch (error) {
        res.status(500).json({ message: 'Failed to mark notification as read', error });
    }
};