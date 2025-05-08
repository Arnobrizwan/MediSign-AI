const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// Triggered when a new Firebase Auth user is created
exports.onNewUser = functions.auth.user().onCreate(async (userRecord) => {
  try {
    const uid = userRecord.uid;
    const email = userRecord.email;

    if (!uid || !email) {
      console.error('❌ Missing UID or email on user record');
      return null;
    }

    console.info(`⚙️ Processing new user: ${email} (${uid})`);

    const apiKey = functions.config().gemini.apikey;

    const geminiResponse = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`,
      {
        contents: [{ parts: [{ text: `Welcome new user ${email}. Generate a friendly onboarding message.` }] }]
      }
    );

    const onboardingMessage =
      geminiResponse?.data?.candidates?.[0]?.content?.parts?.[0]?.text ||
      'Welcome to MediSign AI!';

    await admin.firestore().collection('users').doc(uid).set({
      email,
      role: 'user', // default role
      onboardingMessage,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.info(`✅ Onboarding saved for ${email}`);
    return null;
  } catch (error) {
    console.error(`❌ Error generating onboarding for ${userRecord.email}:`, error.response?.data || error.message);
    return null;
  }
});

// Callable function to get a dynamic welcome message (when user logs in)
exports.getGeminiWelcomeMessage = functions.https.onCall(async (data, context) => {
  const email = data.email;

  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'Email is required.');
  }

  try {
    const apiKey = functions.config().gemini.apikey;

    const geminiResponse = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`,
      {
        contents: [{ parts: [{ text: `Welcome back, ${email}! Generate a cool, fresh welcome message.` }] }]
      }
    );

    const message =
      geminiResponse?.data?.candidates?.[0]?.content?.parts?.[0]?.text ||
      'Welcome back to MediSign AI!';

    return { message };
  } catch (error) {
    console.error('❌ Gemini API error:', error.response?.data || error.message);
    throw new functions.https.HttpsError('internal', 'Failed to generate AI welcome message.');
  }
});