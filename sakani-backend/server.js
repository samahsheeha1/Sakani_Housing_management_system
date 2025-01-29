const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const documentRoutes = require('./routes/documentRoutes');
const roomRoutes = require('./routes/roomRoutes');
const reservationRoutes = require('./routes/ReservationRoutes');
const roommateRoutes = require('./routes/roommateRoutes');
const chatRoutes = require('./routes/chatRoutes');
const { saveMessage } = require('./controllers/chatController'); // Import saveMessage and markAsRead
const Chat = require('./models/Chat'); // Adjust the path to your Chat model
const notificationRoutes = require('./routes/notificationRoutes');
const path = require('path');
const uploadRoutes = require('./routes/uploadRoutes'); // Import your upload routes
const faqroutes=require('./routes/faqRoutes');
const statsRoutes = require('./routes/statsRoutes'); // Import stats routes
const studentRoutes = require('./routes/studentRoutes');
dotenv.config();
connectDB();

const app = express();
const server = http.createServer(app); // Create HTTP server
const io = new Server(server, {
  cors: {
    origin: '*', // Allow any origin
    methods: ['GET', 'POST'],
  },
});

app.use(express.json());
app.use(cors());

// Routes
app.use('/api/users', authRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api', reservationRoutes);
app.use('/api/roommates', roommateRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/api', uploadRoutes);
app.use('/api/faqs',faqroutes);
app.use('/api/stats', statsRoutes);
app.use('/api/student', studentRoutes);

const PORT = process.env.PORT || 5000;

// WebSocket logic
io.on('connection', (socket) => {
  console.log(`[WebSocket] User connected: ${socket.id}`);

  // Join a chat room
  socket.on('joinRoom', ({ roomId }) => {
    if (!roomId) {
      console.error(`[WebSocket] Invalid roomId: ${roomId}`);
      return;
    }
    socket.join(roomId);
    console.log(`[WebSocket] User ${socket.id} joined room: ${roomId}`);
  });

  // Send a message
  socket.on('sendMessage', async ({ roomId, senderId, receiverId, message, fileUrl, fileType }) => {
    console.log(`[WebSocket] Received message: Room ${roomId}, Sender ${senderId}, Message: ${message}, File: ${fileUrl || 'None'}`);
    
    // Construct the message data without using req
    const messageData = {
      senderId,
      receiverId,
      message: message || '',
      fileUrl: fileUrl || '', // Use the fileUrl as provided by the client
      fileType: fileType || 'none',
      timestamp: new Date(),
      read: false,
    };
  
    try {
      const savedMessage = await saveMessage(messageData);
      io.to(roomId).emit('receiveMessage', savedMessage); // Emit the message to the room
    } catch (error) {
      console.error(`[WebSocket] Error saving or broadcasting message: ${error}`);
    }
  });

  // Mark messages as read
  socket.on('markAsRead', async ({ userId, roommateId, roomId }) => {
    if (!userId || !roommateId || !roomId) {
      console.error(`[WebSocket] Invalid data: userId, roommateId, or roomId missing.`);
      return;
    }

    try {
      // Mark messages as read in the database
      await Chat.updateMany(
        { senderId: roommateId, receiverId: userId, read: false },
        { $set: { read: true } }
      );

      console.log(`[WebSocket] Messages marked as read for User: ${userId}`);
      // Notify all clients in the room
      io.to(roomId).emit('messageRead', { userId, roommateId, roomId });
    } catch (error) {
      console.error(`[WebSocket] Error marking messages as read: ${error}`);
    }
  });

  socket.on('uploadFile', async ({ roomId, senderId, receiverId, file, fileType }) => {
    console.log(`[WebSocket] File upload: Room ${roomId}, Sender ${senderId}, FileType: ${fileType}`);
    try {
      // Extract the relative path from the file URL
      const fullUrl = file.url; // Full URL from the frontend, e.g., http://127.0.0.1:5000/uploads/others/filename.png
      const relativePath = fullUrl.replace(/^https?:\/\/[^\/]+/, ''); // Remove the base URL
  
      // Save file message in the database
      const messageData = {
        senderId,
        receiverId,
        fileUrl: relativePath, // Save only the relative path
        fileType: fileType,
        message: '', // No text message for file uploads
        timestamp: new Date(),
        read: false,
      };
  
      const savedMessage = await saveMessage(messageData);
      io.to(roomId).emit('receiveMessage', savedMessage); // Emit the file message to the room
    } catch (error) {
      console.error(`[WebSocket] Error saving or broadcasting file message: ${error}`);
    }
  });

  // Handle user disconnect
  socket.on('disconnect', () => {
    console.log(`[WebSocket] User disconnected: ${socket.id}`);
  });

  // Handle socket errors
  socket.on('error', (err) => {
    console.error(`[WebSocket] Error with socket ${socket.id}: ${err}`);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
