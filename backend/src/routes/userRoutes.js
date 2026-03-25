const express = require('express');
const authMiddleware = require('../middleware/auth');
const { getMe } = require('../controllers/userController');
const {
    getMyProfile,
    updateMyProfile
} = require('../controllers/userProfileController');

const router = express.Router();

router.use(authMiddleware);

router.get('/me', getMe);
router.get('/me/profile', getMyProfile);
router.put('/me/profile', updateMyProfile);

module.exports = router;
