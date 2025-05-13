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

  let onboardingMessage = getRandomFallbackMessage(email);

  try {
    // Updated request format for Gemini API
    const res = await axios.post(GEMINI_ENDPOINT, {
      contents: [
        {
          role: "user",
          parts: [{ text: `Welcome new user ${email}. Generate a friendly onboarding message.` }]
        }
      ],
      generationConfig: {
        temperature: 0.2,
        candidateCount: 1
      }
    }, { timeout: 20000 });

    console.log('✅ Gemini API response:', res.status);
    
    // Updated response parsing
    const candidate = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (candidate) onboardingMessage = candidate;

  } catch (err) {
    console.warn('⚠️ Gemini onboarding fallback:', err.response?.status, err.response?.data || err.message);
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

// —–– 2) Callable: welcome back —––––––––––––––––––––––––––––––––––––––
exports.getGeminiWelcomeMessage = functions.https.onCall(async (data) => {
  const email = data.email;
  if (!email) throw new functions.https.HttpsError('invalid-argument', 'Email is required.');

  let message = getRandomFallbackMessage(email);

  try {
    // Updated request format for Gemini API
    const res = await axios.post(GEMINI_ENDPOINT, {
      contents: [
        {
          role: "user",
          parts: [{ text: `Welcome back, ${email}! Generate a personalized welcome message.` }]
        }
      ],
      generationConfig: {
        temperature: 0.2,
        candidateCount: 1
      }
    }, { timeout: 20000 });

    // Updated response parsing
    const candidate = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (candidate) message = candidate;

  } catch (err) {
    console.warn('⚠️ Gemini welcome fallback:', err.response?.status, err.response?.data || err.message);
  }

  return { message };
});

// —–– 3) Callable: translate text —––––––––––––––––––––––––––––––––––––
const translationClient = new TranslationServiceClient();
exports.translateText = functions.https.onCall(async (data) => {
  const text = data.text;
  const targetLang = data.targetLang || 'en';
  if (!text) throw new functions.https.HttpsError('invalid-argument', 'No text provided.');

  const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
  const request = {
    parent: `projects/${projectId}/locations/global`,
    contents: [text],
    mimeType: 'text/plain',
    targetLanguageCode: targetLang,
  };

  const [response] = await translationClient.translateText(request);
  return { translatedText: response.translations?.[0]?.translatedText || '' };
});

// —–– 4) Callable: chat via Gemini proxy —––––––––––––––––––––––––––––––
exports.chatWithGemini = functions.https.onCall(async (data) => {
  const userInput     = data.userInput;
  const systemPrompt  = data.systemPrompt;
  const temperature   = data.temperature   ?? 0.4;
  const candidateCount= data.candidateCount ?? 1;

  if (typeof userInput !== 'string' || typeof systemPrompt !== 'string') {
    throw new functions.https.HttpsError('invalid-argument',
      'userInput and systemPrompt must be strings');
  }

  // Updated payload format for current Gemini API
  const payload = {
    contents: [
      {
        role: "user",
        parts: [
          { text: systemPrompt },
          { text: userInput }
        ]
      }
    ],
    generationConfig: {
      temperature,
      candidateCount
    }
  };

  console.log('🔄 Sending request to Gemini API...');
  
  try {
    const res = await axios.post(GEMINI_ENDPOINT, payload, {
      timeout: 20000,
      headers: { 'Content-Type': 'application/json' }
    });

    console.log('✅ Gemini API response status:', res.status);
    
    // Updated response parsing
    const candidate = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!candidate) {
      console.error('❌ Gemini returned no candidates:', res.data);
      throw new Error('No candidate in Gemini response');
    }
    
    console.log('✅ Gemini response received successfully');
    return { reply: candidate };

  } catch (err) {
    console.error('❌ Gemini API error:', err.response?.status, err.response?.data || err.message);
    throw new functions.https.HttpsError('internal', 'Failed to fetch from Gemini');
  }
});