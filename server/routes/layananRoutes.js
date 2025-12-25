const express = require('express');
const router = express.Router();
const layananController = require('../controllers/layananController');

// Get all layanan
router.get('/', layananController.getAllLayanan);

//  Create new layanan
router.post('/', layananController.createLayanan);

// Update layanan
router.put('/:id', layananController.updateLayanan);

// Delete layanan
router.delete('/:id', layananController.deleteLayanan);

module.exports = router;
