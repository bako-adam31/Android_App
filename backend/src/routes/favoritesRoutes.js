const express = require('express');
const authMiddleware = require('../middleware/auth');
const {
    getFavorites,
    addFavorite,
    removeFavorite
} = require('../controllers/favoritesController');

const router = express.Router();

router.use(authMiddleware);

router.get('/', getFavorites);
router.post('/add', addFavorite);
router.post('/remove', removeFavorite);

module.exports = router;