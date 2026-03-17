require('dotenv').config();

const app = require('./app');
const { initializeFirebaseAdmin } = require('./config/firebase');

const PORT = process.env.PORT || 5000;

// Initialize Firebase Admin once at startup
initializeFirebaseAdmin();

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});