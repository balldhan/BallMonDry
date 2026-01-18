const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Get Layanan
router.get('/layanan', orderController.getLayanan);

// Create new order (CLIENT)
router.post('/', orderController.createOrder);

// Get all orders (ADMIN)
router.get('/', orderController.getAllOrders);

// Get order history by user
router.get('/history/:user_id', orderController.getOrderHistory);

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
