const Document = require('../models/Document');

// Controller method to fetch documents by user ID
exports.getDocumentsByUserId = async (req, res) => {
    const { userId } = req.params;
    try {
      const documents = await Document.find({ user: userId });
      res.status(200).json(documents);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching documents', error });
    }
  };