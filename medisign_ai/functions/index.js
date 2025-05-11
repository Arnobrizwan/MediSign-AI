// functions/index.js

// Import the v1 entry-point so auth.user and https.onCall still work
const functions = require('firebase-functions/v1');
const admin     = require('firebase-admin');
const axios     = require('axios');
const { TranslationServiceClient } = require('@google-cloud/translate').v3;

// Initialize the Admin SDK
admin.initializeApp();

// —— Cloud Translate client —— 
const translationClient = new TranslationServiceClient();

// —— Gemini API config —— 
const GEMINI_API_KEY = 'AIzaSyDL39pCbA5sdtx1V3S7SCfq2cGMbohIOe8';  // Replace with your key
const GEMINI_API_URL =
  `https://generativelanguage.googleapis.com/v1/models/` +
  `gemini-1.5-pro-latest:generateContent?key=${GEMINI_API_KEY}`;

// Simple fallback templates
function getRandomFallbackMessage(email) {
  const user = email.split('@')[0];
  const msgs = [
    `Welcome to MediSign AI, ${user}! Ready to break down communication barriers?`,
    `Hello ${user}! MediSign AI is here to make healthcare accessible.`,
    `Welcome back, ${user}! Let's continue making communication easier.`,
    `Great to see you, ${user}! Your accessible healthcare journey starts now.`,
    `Hi ${user}! Together, we'll make healthcare communication seamless.`,
  ];
  return msgs[Math.floor(Math.random() * msgs.length)];
}

/**
 * 1) Auth trigger: when a new user signs up
 */
exports.onNewUser = functions.auth.user().onCreate(async (userRecord) => {
  const { uid, email } = userRecord;
  if (!uid || !email) {
    console.error('❌ Missing UID or email on new user');
    return null;
  }

  let onboardingMessage = getRandomFallbackMessage(email);

  // Try Gemini for a dynamic message
  try {
    const res = await axios.post(
      GEMINI_API_URL,
      {
        contents: [{
          parts: [{
            text: `Welcome new user ${email}. Generate a friendly onboarding message for a healthcare communication app.`
          }]
        }]
      },
      { timeout: 5000 }
    );
    const part = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (part) onboardingMessage = part;
  } catch (err) {
    console.warn('⚠️ Gemini API fallback:', err.message);
  }

  await admin.firestore().collection('users').doc(uid).set({
    uid,
    email,
    role: 'user',
    onboardingMessage,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`✅ Onboarding saved for ${email}`);
  return null;
});

/**
 * 2) Callable: personalized welcome on login
 */
exports.getGeminiWelcomeMessage = functions.https.onCall(async (data, context) => {
  const email = data.email;
  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'Email is required.');
  }

  let message = getRandomFallbackMessage(email);

  // Try Gemini for personalized welcome
  try {
    const res = await axios.post(
      GEMINI_API_URL,
      {
        contents: [{
          parts: [{
            text: `Welcome back, ${email}! Generate a personalized, encouraging welcome message for a healthcare communication app user.`
          }]
        }]
      },
      { timeout: 5000 }
    );
    const part = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (part) message = part;
  } catch (err) {
    console.warn('⚠️ Gemini welcome fallback:', err.message);
  }

  return { message };
});

/**
 * 3) Callable: translateText via Cloud Translate API
 */
exports.translateText = functions.https.onCall(async (data, context) => {
  const text       = data.text;
  const targetLang = data.targetLang || 'en';
  if (!text) {
    throw new functions.https.HttpsError('invalid-argument', 'No text provided.');
  }

  const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
  const location  = 'global';

  const request = {
    parent: `projects/${projectId}/locations/${location}`,
    contents: [text],
    mimeType: 'text/plain',
    targetLanguageCode: targetLang,
  };

  try {
    const [response] = await translationClient.translateText(request);
    const translated = response.translations?.[0]?.translatedText || '';
    return { translatedText: translated };
  } catch (err) {
    console.error('❌ Translate API error:', err);
    throw new functions.https.HttpsError('internal', 'Translation failed');
  }
});