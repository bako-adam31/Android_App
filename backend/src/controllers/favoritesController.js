const favoritesService = require('../services/favoritesService');

const getFavorites = async (req, res, next) => {
    try {
        const uid = req.user.uid;
        const favorites = await favoritesService.getAllFavorites(uid);

        res.status(200).json({
            success: true,
            count: favorites.length,
            favorites
        });
    } catch (error) {
        next(error);
    }
};

const addFavorite = async (req, res, next) => {
    try {
        const uid = req.user.uid;
        const { perfume } = req.body;

        const result = await favoritesService.addFavorite(uid, perfume);

        res.status(result.created ? 201 : 200).json({
            success: true,
            message: result.created
                ? 'Favorite added successfully'
                : 'Favorite already exists',
            favorite: result.favorite
        });
    } catch (error) {
        next(error);
    }
};

const removeFavorite = async (req, res, next) => {
    try {
        const uid = req.user.uid;
        const { perfumeId } = req.body;

        const result = await favoritesService.removeFavorite(uid, perfumeId);

        res.status(200).json({
            success: true,
            message: result.removed
                ? 'Favorite removed successfully'
                : 'Favorite not found',
            perfumeId: result.perfumeId
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getFavorites,
    addFavorite,
    removeFavorite
};