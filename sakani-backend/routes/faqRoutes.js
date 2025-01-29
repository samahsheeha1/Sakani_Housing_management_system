const express = require('express');
const faqController = require('../controllers/faqController');

const router = express.Router();

// GET /api/faqs
router.get('/', faqController.getFAQs);

module.exports = router;