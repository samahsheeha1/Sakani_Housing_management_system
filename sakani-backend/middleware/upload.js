const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Create dynamic storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let userFolder;

    // Use the `uploads/pictures` folder specifically for signup pictures
    if (req.body.isSignup) {
      userFolder = './uploads/pictures';
    } else if (req.body.chatFolder) {
      userFolder = `./uploads/chats/${req.body.chatFolder}`;
    } else if (req.user && req.user.id) {
      userFolder = `./uploads/${req.user.id}`;
    } else {
      userFolder = './uploads/others';
    }

    // Create folder if it doesn't exist
    if (!fs.existsSync(userFolder)) {
      fs.mkdirSync(userFolder, { recursive: true });
    }
    cb(null, userFolder);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});

// File filter to validate type and extension
const fileFilter = (req, file, cb) => {
  const allowedExtensions = ['.pdf', '.jpeg', '.jpg', '.png'];

  const fileExtension = path.extname(file.originalname).toLowerCase();
  console.log(`File mimetype: ${file.mimetype}, Extension: ${fileExtension}`);

  // Handle mobile-specific cases with application/octet-stream
  if (
    allowedExtensions.includes(fileExtension) ||
    (file.mimetype === 'application/octet-stream' &&
      (fileExtension === '.pdf' || fileExtension === '.jpg' || fileExtension === '.png'))
  ) {
    cb(null, true);
  } else {
    console.error(
      `Invalid file type: ${file.mimetype}, Extension: ${fileExtension}`
    );
    cb(new Error('Invalid file type. Only PDF, JPEG, and PNG are allowed.'));
  }
};

// Configure multer
const upload = multer({ storage, fileFilter });

module.exports = upload;
