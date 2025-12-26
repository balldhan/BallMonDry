const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Create new order (CLIENT)
router.post('/', orderController.createOrder);

// Get all orders (ADMIN)
router.get('/', orderController.getAllOrders);

// Update order by client
router.put('/edit-client', orderController.updateOrderByClient);

// Update order by admin
router.put('/update', orderController.updateOrderByAdmin);

// Cancel/delete order (CLIENT)
router.delete('/:id', orderController.deleteOrder);

// Payment endpoints
router.post('/payment/metode', orderController.pilihMetodePembayaran);
router.post('/payment/upload-bukti', orderController.uploadBuktiTransfer);
router.post('/payment/verifikasi', orderController.verifikasiPembayaran);

module.exports = router;
