// functions/index.js

const functions = require('firebase-functions/v1');
const admin     = require('firebase-admin');
const axios     = require('axios');
const { TranslationServiceClient } = require('@google-cloud/translate').v3;

// — initialize —
admin.initializeApp();

// —–– CONFIG —––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
const GEMINI_API_KEY = 'AIzaSyDL39pCbA5sdtx1V3S7SCfq2cGMbohIOe8';

// Updated to use the current Gemini API endpoint
const GEMINI_ENDPOINT = 
  `https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=${GEMINI_API_KEY}`;

// simple fallback for welcomes
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

// —–– 1) Auth trigger: new user —––––––––––––––––––––––––––––––––––––––
exports.onNewUser = functions.auth.user().onCreate(async (userRecord) => {
  const { uid, email } = userRecord;
  if (!uid || !email) {
    console.error('❌ Missing UID or email on new user');
    return null;
  }

  // Skip Gemini API call and use the fallback message directly
  let onboardingMessage = getRandomFallbackMessage(email);

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

// —–– 2) Callable: welcome back —––––––––––––––––––––––––––––––––––––––
exports.getGeminiWelcomeMessage = functions.https.onCall(async (data) => {
  const email = data.email;
  if (!email) throw new functions.https.HttpsError('invalid-argument', 'Email is required.');

  // Skip Gemini API call and use the fallback message directly
  const message = getRandomFallbackMessage(email);
  return { message };
});

// —–– 3) Callable: translate text —––––––––––––––––––––––––––––––––––––
exports.translateText = functions.https.onCall(async (data) => {
  // Initialize client inside the function instead of globally
  const translationClient = new TranslationServiceClient();
  
  const text = data.text;
  const targetLang = data.targetLang || 'en';
  if (!text) throw new functions.https.HttpsError('invalid-argument', 'No text provided.');

  try {
    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    const request = {
      parent: `projects/${projectId}/locations/global`,
      contents: [text],
      mimeType: 'text/plain',
      targetLanguageCode: targetLang,
    };

    const [response] = await translationClient.translateText(request);
    return { translatedText: response.translations?.[0]?.translatedText || '' };
  } catch (err) {
    console.error('❌ Translation API error:', err);
    throw new functions.https.HttpsError('internal', 'Translation failed: ' + err.message);
  }
});

// —–– 4) Callable: chat via Gemini proxy —––––––––––––––––––––––––––––––
// This function serves as a placeholder that returns a fallback message
// since you're implementing Gemini API directly in your frontend
exports.chatWithGemini = functions.https.onCall(async (data) => {
  const userInput = data.userInput || '';
  
  return { 
    reply: "I'm processing your request through the frontend Gemini API implementation. If you're seeing this message, please ensure you're using the latest version of the app."
  };
});