const admin = require('firebase-admin');

let firebaseApp = null;

const initializeFirebaseAdmin = () => {
    if (firebaseApp) {
        return firebaseApp;
    }

    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;

    if (!projectId || !clientEmail || !privateKey) {
        throw new Error('Missing Firebase Admin environment variables');
    }

    firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey: privateKey.replace(/\\n/g, '\n')
        })
    });

    return firebaseApp;
};

const getFirebaseAdmin = () => {
    if (!firebaseApp) {
        initializeFirebaseAdmin();
    }

    return admin;
};

module.exports = {
    initializeFirebaseAdmin,
    getFirebaseAdmin
};