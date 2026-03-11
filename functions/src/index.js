const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

async function ensureAdminCaller(uid) {
    if (!uid) {
        throw new HttpsError('unauthenticated', 'Usuário não autenticado.');
    }

    const userDoc = await db.collection('users').doc(uid).get();
    const role = userDoc.data()?.role;

    if (role !== 'admin') {
        throw new HttpsError(
            'permission-denied',
            'Apenas administradores podem executar esta ação.',
        );
    }
}

exports.adminCreateUser = onCall(async (request) => {
    await ensureAdminCaller(request.auth?.uid);

    const email = String(request.data?.email || '').trim().toLowerCase();
    const password = String(request.data?.password || '').trim();
    const role = String(request.data?.role || 'leader').trim().toLowerCase();
    const congregationId = request.data?.congregationId
        ? String(request.data.congregationId).trim()
        : null;

    if (!email) {
        throw new HttpsError('invalid-argument', 'E-mail é obrigatório.');
    }

    if (password.length < 6) {
        throw new HttpsError(
            'invalid-argument',
            'A senha precisa ter ao menos 6 caracteres.',
        );
    }

    if (role !== 'admin' && role !== 'leader') {
        throw new HttpsError('invalid-argument', 'Papel inválido.');
    }

    if (role === 'leader' && !congregationId) {
        throw new HttpsError(
            'invalid-argument',
            'Para líder, congregationId é obrigatório.',
        );
    }

    const userRecord = await admin.auth().createUser({
        email,
        password,
        emailVerified: false,
    });

    await db.collection('users').doc(userRecord.uid).set({
        email,
        role,
        congregationId: role === 'leader' ? congregationId : null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: request.auth.uid,
    });

    return { uid: userRecord.uid };
});

exports.adminUpdateUserProfile = onCall(async (request) => {
    await ensureAdminCaller(request.auth?.uid);

    const uid = String(request.data?.uid || '').trim();
    const email = String(request.data?.email || '').trim().toLowerCase();
    const role = String(request.data?.role || 'leader').trim().toLowerCase();
    const congregationId = request.data?.congregationId
        ? String(request.data.congregationId).trim()
        : null;

    if (!uid) {
        throw new HttpsError('invalid-argument', 'UID é obrigatório.');
    }

    if (!email) {
        throw new HttpsError('invalid-argument', 'E-mail é obrigatório.');
    }

    if (role !== 'admin' && role !== 'leader') {
        throw new HttpsError('invalid-argument', 'Papel inválido.');
    }

    if (role === 'leader' && !congregationId) {
        throw new HttpsError(
            'invalid-argument',
            'Para líder, congregationId é obrigatório.',
        );
    }

    await admin.auth().updateUser(uid, { email });

    await db.collection('users').doc(uid).set(
        {
            email,
            role,
            congregationId: role === 'leader' ? congregationId : null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedBy: request.auth.uid,
        },
        { merge: true },
    );

    return { success: true };
});

exports.adminDeleteUser = onCall(async (request) => {
    await ensureAdminCaller(request.auth?.uid);

    const uid = String(request.data?.uid || '').trim();
    if (!uid) {
        throw new HttpsError('invalid-argument', 'UID é obrigatório.');
    }

    if (uid === request.auth.uid) {
        throw new HttpsError(
            'failed-precondition',
            'Não é permitido excluir o próprio usuário.',
        );
    }

    await admin.auth().deleteUser(uid);
    await db.collection('users').doc(uid).delete();

    return { success: true };
});
