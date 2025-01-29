const Room = require('../models/Room');

exports.getRooms = async (req, res) => {
  try {
    const rooms = await Room.find();
    res.status(200).json(rooms);
  } catch (error) {
    console.error('Error fetching rooms:', error);
    res.status(500).json({ message: 'Server error' });
  }
};



// Fetch all rooms (with optional owner filter)
exports.getAllRooms = async (req, res) => {
  try {
    const { owner } = req.query; // Get the owner ID from the query parameter

    // Build the query
    const query = owner ? { owner } : {};

    // Fetch rooms from the database
    const rooms = await Room.find(query).populate('owner', 'fullName email'); // Populate owner details if needed

    res.status(200).json(rooms); // Return the rooms
  } catch (error) {
    console.error('Error fetching rooms:', error);
    res.status(500).json({ message: 'Failed to fetch rooms' });
  }
};

// Search rooms (with optional owner filter)
exports.searchRoomss = async (req, res) => {
  try {
    const { query, searchBy, owner } = req.query; // Get search query, searchBy, and owner from query parameters

    // Build the search query
    const searchQuery = owner ? { owner, [searchBy]: { $regex: query, $options: 'i' } } : { [searchBy]: { $regex: query, $options: 'i' } };

    // Fetch rooms from the database
    const rooms = await Room.find(searchQuery).populate('owner', 'fullName email'); // Populate owner details if needed

    res.status(200).json(rooms); // Return the rooms
  } catch (error) {
    console.error('Error searching rooms:', error);
    res.status(500).json({ message: 'Failed to search rooms' });
  }
};

// Get a single room by ID
exports.getRoomById = async (req, res) => {
  try {
    const room = await Room.findById(req.params.id);
    if (!room) {
      return res.status(404).json({ message: 'Room not found' });
    }
    res.status(200).json(room);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching room', error: error.message });
  }
};

// Update a room
exports.updateRoom = async (req, res) => {
  try {
    const updatedRoom = await Room.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!updatedRoom) {
      return res.status(404).json({ message: 'Room not found' });
    }
    res.status(200).json({ message: 'Room updated successfully', room: updatedRoom });
  } catch (error) {
    res.status(500).json({ message: 'Error updating room', error: error.message });
  }
};

// Delete a room
exports.deleteRoom = async (req, res) => {
  try {
    const deletedRoom = await Room.findByIdAndDelete(req.params.id);
    if (!deletedRoom) {
      return res.status(404).json({ message: 'Room not found' });
    }
    res.status(200).json({ message: 'Room deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting room', error: error.message });
  }
};

// Search rooms by type, price, or availability
exports.searchRooms = async (req, res) => {
  const { query } = req.query; // Get the search query from the request

  try {
    // Create a search query object
    const searchQuery = {
      $or: [
        { type: { $regex: query, $options: 'i' } }, // Case-insensitive search by type
        { price: { $regex: query, $options: 'i' } }, // Case-insensitive search by price
        { availability: { $regex: query, $options: 'i' } }, // Case-insensitive search by availability
      ],
    };

    // Fetch rooms matching the search query
    const rooms = await Room.find(searchQuery);
    res.status(200).json(rooms);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createRoom = async (req, res) => {
  const { type, price, availability, address, latitude, longitude, beds, images } = req.body; // Destructure request body
  const userId = req.user.id; // Get user ID from token
  const role = req.user.role; // Get user role from token

  console.log('Request body:', req.body); // Debugging

  try {
    // Validate required fields
    if (!type || !price || !availability || !address || !latitude || !longitude || !beds || !images) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    // Create a new room document
    const newRoom = new Room({
      type,
      price,
      availability,
      address,
      latitude,
      longitude,
      beds,
      images,
      owner: role === 'Room Owner' ? userId : userId, // Set owner if the user is a Room Owner
    });

    // Save the room to the database
    await newRoom.save();

    // Return the created room
    res.status(201).json(newRoom);
  } catch (error) {
    // Handle errors
    console.error('Error creating room:', error); // Debugging
    res.status(500).json({ message: 'Error creating room', error: error.message });
  }
};

// Get featured rooms (isFeatured: true)
exports.getFeaturedRooms = async (req, res) => {
  try {
    const featuredRooms = await Room.find({ isFeatured: true });
    res.status(200).json(featuredRooms);
  } catch (error) {
    console.error('Error fetching featured rooms:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get most visited rooms (sorted by visits in descending order and visits > 70)
exports.getMostVisitedRooms = async (req, res) => {
  try {
    const mostVisitedRooms = await Room.find({ visits: { $gt: 70 } }).sort({ visits: -1 });
    res.status(200).json(mostVisitedRooms);
  } catch (error) {
    console.error('Error fetching most visited rooms:', error);
    res.status(500).json({ message: 'Server error' });
  }
};


// Fetch rooms owned by a specific user
exports.getRoomsByOwner = async (req, res) => {
  try {
    const { ownerId } = req.params;

    // Find rooms where the owner matches the provided ID
    const rooms = await Room.find({ owner: ownerId }).select('_id type price address');

    res.status(200).json(rooms);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch rooms', error: error.message });
  }
};

exports.updateRoomAvailability = async (req, res) => {
  const { roomId } = req.params;

  try {
    // Find the room by ID and update its availability to "Fully Booked"
    const updatedRoom = await Room.findByIdAndUpdate(
      roomId,
      { availability: 'Fully Booked' }, // Hardcoded value
      { new: true }
    );

    if (!updatedRoom) {
      return res.status(404).json({ message: 'Room not found' });
    }

    res.status(200).json(updatedRoom);
  } catch (error) {
    res.status(500).json({ message: 'Error updating room availability', error });
  }
};