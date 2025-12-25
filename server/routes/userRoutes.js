const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Get all users (CLIENT only)
router.get('/', userController.getAllUsers);

// Get single user by ID
router.get('/:id', userController.getUserById);

// Update user profile
router.put('/update', userController.updateUser);

module.exports = router;
