const { getFirebaseAdmin } = require('../config/firebase');

const getFirestore = () => {
    const admin = getFirebaseAdmin();
    return admin.firestore();
};

const getUserFavoritesCollection = (uid) => {
    const db = getFirestore();
    return db.collection('users').doc(uid).collection('favorites');
};

const getAllFavorites = async (uid) => {
    const favoritesRef = getUserFavoritesCollection(uid);
    const snapshot = await favoritesRef.get();

    return snapshot.docs.map((doc) => ({
        perfumeId: doc.id,
        ...doc.data()
    }));
};

const addFavorite = async (uid, perfume) => {
    if (!perfume || typeof perfume !== 'object') {
        const error = new Error('Perfume object is required');
        error.statusCode = 400;
        throw error;
    }

    const perfumeId = perfume.perfumeId || perfume.id || perfume._id;

    if (!perfumeId) {
        const error = new Error('perfumeId is required');
        error.statusCode = 400;
        throw error;
    }

    const favoritesRef = getUserFavoritesCollection(uid);
    const favoriteDocRef = favoritesRef.doc(String(perfumeId));

    const existingDoc = await favoriteDocRef.get();

    if (existingDoc.exists) {
        return {
            created: false,
            favorite: {
                perfumeId: String(perfumeId),
                ...existingDoc.data()
            }
        };
    }

    const favoriteData = {
        ...perfume,
        perfumeId: String(perfumeId),
        createdAt: new Date().toISOString()
    };

    await favoriteDocRef.set(favoriteData);

    return {
        created: true,
        favorite: favoriteData
    };
};

const removeFavorite = async (uid, perfumeId) => {
    if (!perfumeId) {
        const error = new Error('perfumeId is required');
        error.statusCode = 400;
        throw error;
    }

    const favoritesRef = getUserFavoritesCollection(uid);
    const favoriteDocRef = favoritesRef.doc(String(perfumeId));
    const existingDoc = await favoriteDocRef.get();

    if (!existingDoc.exists) {
        return {
            removed: false,
            perfumeId: String(perfumeId)
        };
    }

    await favoriteDocRef.delete();

    return {
        removed: true,
        perfumeId: String(perfumeId)
    };
};

module.exports = {
    getAllFavorites,
    addFavorite,
    removeFavorite
};