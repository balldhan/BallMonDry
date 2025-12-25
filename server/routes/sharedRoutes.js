const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Get admin statistics
router.get('/stats', orderController.getAdminStats);

// Get order history by user (CLIENT)
router.get('/:user_id', orderController.getOrderHistory);

module.exports = router;
