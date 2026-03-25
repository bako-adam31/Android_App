const userProfileService = require('../services/userProfileService');

const getMyProfile = async (req, res, next) => {
    try {
        const profile = await userProfileService.getProfile({
            uid: req.user.uid,
            email: req.user.email || null
        });

        res.status(200).json({
            success: true,
            profile
        });
    } catch (error) {
        next(error);
    }
};

const updateMyProfile = async (req, res, next) => {
    try {
        const profile = await userProfileService.upsertProfile({
            uid: req.user.uid,
            email: req.user.email || null,
            payload: req.body || {}
        });

        res.status(200).json({
            success: true,
            message: 'Profile saved successfully',
            profile
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getMyProfile,
    updateMyProfile
};
