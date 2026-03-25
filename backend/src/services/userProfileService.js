const { getFirebaseAdmin } = require('../config/firebase');

const BIO_MAX_LENGTH = 120;
const ALLOWED_GENDERS = ['male', 'female'];
const ALLOWED_ACCORDS = [
    'woody',
    'gourmand',
    'citrus',
    'warm spicy',
    'fruity',
    'aromatic',
    'leather',
    'smoky',
    'amber'
];

const getFirestore = () => {
    const admin = getFirebaseAdmin();
    return admin.firestore();
};

const getUserDocumentRef = (uid) => {
    const db = getFirestore();
    return db.collection('users').doc(uid);
};

const createValidationError = (message) => {
    const error = new Error(message);
    error.statusCode = 400;
    return error;
};

const normalizeNullableString = (value) => {
    if (value === undefined || value === null) {
        return null;
    }

    const normalized = String(value).trim();
    return normalized.isEmpty ? null : normalized;
};

const normalizeBio = (value) => {
    if (value === undefined || value === null) {
        return '';
    }

    if (typeof value !== 'string') {
        throw createValidationError('bio must be a string');
    }

    const normalized = value.trim();
    if (normalized.length > BIO_MAX_LENGTH) {
        throw createValidationError(`bio must be ${BIO_MAX_LENGTH} characters or fewer`);
    }

    return normalized;
};

const normalizeGender = (value, { strict = true } = {}) => {
    const normalized = normalizeNullableString(value)?.toLowerCase();

    if (!normalized) {
        return null;
    }

    if (!ALLOWED_GENDERS.includes(normalized)) {
        if (!strict) {
            return null;
        }

        throw createValidationError('gender must be either male or female');
    }

    return normalized;
};

const normalizeFavoriteAccord = (value, { strict = true } = {}) => {
    const normalized = normalizeNullableString(value)?.toLowerCase();

    if (!normalized) {
        return null;
    }

    if (!ALLOWED_ACCORDS.includes(normalized)) {
        if (!strict) {
            return null;
        }

        throw createValidationError(
            `favoriteAccord must be one of: ${ALLOWED_ACCORDS.join(', ')}`
        );
    }

    return normalized;
};

const sanitizeSignatureFragrance = (value, { strict = true } = {}) => {
    if (value === undefined || value === null) {
        return null;
    }

    if (typeof value !== 'object' || Array.isArray(value)) {
        if (!strict) {
            return null;
        }

        throw createValidationError('signatureFragrance must be an object or null');
    }

    const perfumeId = normalizeNullableString(value.perfumeId || value.id || value._id);
    const name = normalizeNullableString(value.name || value.Name);
    const brand = normalizeNullableString(value.brand || value.Brand);

    if (!name) {
        if (!strict) {
            return null;
        }

        throw createValidationError('signatureFragrance.name is required');
    }

    if (!brand) {
        if (!strict) {
            return null;
        }

        throw createValidationError('signatureFragrance.brand is required');
    }

    return {
        perfumeId,
        name,
        brand,
        imageUrl: normalizeNullableString(value.imageUrl || value['Image URL']),
        mainAccords: normalizeNullableString(
            value.mainAccords || value['Main Accords']
        ),
        gender: normalizeNullableString(value.gender || value.Gender),
        year: normalizeNullableString(value.year || value.Year),
        rating: normalizeNullableString(value.rating || value.Rating)
    };
};

const serializeTimestamp = (value) => {
    if (!value) {
        return null;
    }

    if (typeof value === 'string') {
        return value;
    }

    if (typeof value.toDate === 'function') {
        return value.toDate().toISOString();
    }

    return String(value);
};

const buildProfileDocument = ({
    uid,
    email = null,
    data = {}
}) => {
    return {
        uid,
        email: data.email || email || null,
        bio: typeof data.bio === 'string' ? data.bio.trim() : '',
        gender: normalizeGender(data.gender, { strict: false }),
        favoriteAccord: normalizeFavoriteAccord(data.favoriteAccord, { strict: false }),
        signatureFragrance: sanitizeSignatureFragrance(data.signatureFragrance, {
            strict: false
        }),
        createdAt: serializeTimestamp(data.createdAt),
        updatedAt: serializeTimestamp(data.updatedAt)
    };
};

const ensureUserProfileDocument = async ({ uid, email = null }) => {
    const userRef = getUserDocumentRef(uid);
    const snapshot = await userRef.get();

    if (snapshot.exists) {
        return {
            ref: userRef,
            profile: buildProfileDocument({
                uid,
                email,
                data: snapshot.data() || {}
            })
        };
    }

    const now = new Date().toISOString();
    const profile = {
        uid,
        email,
        bio: '',
        gender: null,
        favoriteAccord: null,
        signatureFragrance: null,
        createdAt: now,
        updatedAt: now
    };

    await userRef.set(profile, { merge: true });

    return {
        ref: userRef,
        profile
    };
};

const getProfile = async ({ uid, email = null }) => {
    const { profile } = await ensureUserProfileDocument({ uid, email });
    return profile;
};

const upsertProfile = async ({ uid, email = null, payload = {} }) => {
    const { ref, profile: existingProfile } = await ensureUserProfileDocument({
        uid,
        email
    });

    const now = new Date().toISOString();
    const nextProfile = {
        uid,
        email: email || existingProfile.email || null,
        bio: normalizeBio(payload.bio),
        gender: normalizeGender(payload.gender),
        favoriteAccord: normalizeFavoriteAccord(payload.favoriteAccord),
        signatureFragrance: sanitizeSignatureFragrance(payload.signatureFragrance),
        createdAt: existingProfile.createdAt || now,
        updatedAt: now
    };

    await ref.set(nextProfile, { merge: true });

    return nextProfile;
};

module.exports = {
    ALLOWED_GENDERS,
    ALLOWED_ACCORDS,
    BIO_MAX_LENGTH,
    getProfile,
    upsertProfile
};
