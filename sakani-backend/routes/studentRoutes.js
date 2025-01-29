const express = require('express');

const {
    deleteStudent
  } = require('../controllers/studentController');
  

  const router = express.Router();

router.delete('/:id', deleteStudent);


module.exports = router;