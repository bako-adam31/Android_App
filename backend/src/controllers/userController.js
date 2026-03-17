const getMe = (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Authenticated user fetched successfully',
        user: req.user
    });
};

module.exports = {
    getMe
};