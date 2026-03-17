const express = require('express');
const healthRoutes = require('./healthRoutes');
const userRoutes = require('./userRoutes');
const favoritesRoutes = require('./favoritesRoutes');

const router = express.Router();

router.use('/health', healthRoutes);
router.use('/users', userRoutes);
router.use('/favorites', favoritesRoutes);

module.exports = router;