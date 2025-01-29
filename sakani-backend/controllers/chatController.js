const Chat = require('../models/Chat');
const User = require('../models/User');

// Save a message to the database (called by WebSocket or REST API)
exports.saveMessage = async (data) => {
  console.log(`[ChatController] Saving message: ${JSON.stringify(data)}`);
  try {
    // Include fileUrl and fileType in the message data, default to empty if not provided
    const newMessage = new Chat({
      ...data,
      fileUrl: data.fileUrl || '',
      fileType: data.fileType || 'none', // 'none' for text-only messages
      read: false,
      deletedFor: [],
    });

    const savedMessage = await newMessage.save();
    console.log(`[ChatController] Message saved: ${savedMessage}`);
    return savedMessage;
  } catch (error) {
    console.error(`[ChatController] Error saving message: ${error}`);
    throw error;
  }
};

// Get chat history between two users
exports.getMessages = async (req, res) => {
  try {
    const { userId, roommateId } = req.params;

    const messages = await Chat.find({
      $or: [
        { senderId: userId, receiverId: roommateId },
        { senderId: roommateId, receiverId: userId },
      ],
      deletedFor: { $ne: userId }, // Exclude messages deleted for the user
    })
      .sort({ timestamp: 1 })
      .select('-deletedFor'); // Exclude the `deletedFor` field from the response

    res.status(200).json(messages);
  } catch (error) {
    console.error(`[ChatController] Error fetching messages: ${error}`);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
};

// Mark messages as deleted for the user
exports.deleteChat = async (req, res) => {
  try {
    const { userId, roommateId } = req.body;

    await Chat.updateMany(
      {
        $or: [
          { senderId: userId, receiverId: roommateId },
          { senderId: roommateId, receiverId: userId },
        ],
      },
      { $addToSet: { deletedFor: userId } } // Add userId to the `deletedFor` array
    );

    console.log(`[ChatController] Chat marked as deleted for user: ${userId}`);
    res.status(200).json({ message: 'Chat marked as deleted successfully.' });
  } catch (error) {
    console.error(`[ChatController] Error deleting chat: ${error}`);
    res.status(500).json({ error: 'Failed to delete chat.' });
  }
};

// Mark messages as read for a user
exports.markAsRead = async (req, res) => {
  try {
    const { userId, roommateId } = req.body;

    if (!userId || !roommateId) {
      return res.status(400).json({ error: 'Missing userId or roommateId' });
    }

    // Update unread messages for the user
    const result = await Chat.updateMany(
      { senderId: roommateId, receiverId: userId, read: false },
      { $set: { read: true } }
    );

    console.log(`[ChatController] Messages marked as read: ${result.nModified}`);
    res.status(200).json({ message: 'Messages marked as read successfully.' });
  } catch (error) {
    console.error(`[ChatController] Error marking messages as read: ${error}`);
    res.status(500).json({ error: 'Failed to mark messages as read.' });
  }
};

// Upload a file and save the message
exports.uploadFileAndSaveMessage = async (req, res) => {
  try {
    const { senderId, receiverId, message } = req.body;

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const fileUrl = `uploads/others/${req.file.filename}`;
    const fileType = req.file.mimetype.startsWith('image/') ? 'image' : 'document';

    const newMessage = new Chat({
      senderId,
      receiverId,
      message: message || '',
      fileUrl,
      fileType,
      read: false,
      deletedFor: [],
    });

   const savedMessage = await newMessage.save();

    console.log(`[ChatController] File uploaded and message saved: ${savedMessage}`);
    res.status(201).json(savedMessage);
  } catch (error) {
    console.error(`[ChatController] Error uploading file or saving message: ${error}`);
    res.status(500).json({ error: 'Failed to upload file or save message' });
  }
};
