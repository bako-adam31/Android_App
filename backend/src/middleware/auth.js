const { getFirebaseAdmin } = require('../config/firebase');

const authMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader) {
            return res.status(401).json({
                success: false,
                message: 'Authorization header is missing'
            });
        }

        if (!authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'Invalid authorization header format'
            });
        }

        const idToken = authHeader.substring('Bearer '.length).trim();

        if (!idToken) {
            return res.status(401).json({
                success: false,
                message: 'Firebase ID token is missing'
            });
        }

        const admin = getFirebaseAdmin();
        const decodedToken = await admin.auth().verifyIdToken(idToken);

        req.user = {
            uid: decodedToken.uid,
            email: decodedToken.email || null
        };

        next();
    } catch (error) {
        console.error('Firebase token verification failed', {
            code: error.code,
            message: error.message,
            projectId: process.env.FIREBASE_PROJECT_ID
        });

        return res.status(401).json({
            success: false,
            message: 'Invalid or expired Firebase ID token'
        });
    }
};

module.exports = authMiddleware;
