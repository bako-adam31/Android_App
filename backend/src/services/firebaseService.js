const { getFirebaseAdmin } = require('../config/firebase');

const verifyFirebaseToken = async (idToken) => {
    const admin = getFirebaseAdmin();

    if (!idToken) {
        const error = new Error('Missing Firebase ID token');
        error.statusCode = 401;
        throw error;
    }

    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        return decodedToken;
    } catch (err) {
        const error = new Error('Invalid or expired Firebase ID token');
        error.statusCode = 401;
        throw error;
    }
};

module.exports = {
    verifyFirebaseToken
};