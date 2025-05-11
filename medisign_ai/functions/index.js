const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
admin.initializeApp();

// Gemini API configuration (you can still test with it when you have billing enabled)
const GEMINI_API_KEY = 'AIzaSyDL39pCbA5sdtx1V3S7SCfq2cGMbohIOe8'; // Replace with your key
const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-latest:generateContent?key=${GEMINI_API_KEY}`;

// Fallback messages for prototype
const FALLBACK_MESSAGES = [
  "Welcome to MediSign AI! We're excited to help bridge communication barriers.",
  "Hello! MediSign AI is here to make healthcare communication accessible for everyone.",
  "Welcome back! Let's make communication barriers a thing of the past.",
  "Great to see you! MediSign AI is ready to assist with your communication needs.",
  "Welcome! Transform your healthcare communication experience with MediSign AI.",
  "Welcome to our accessible healthcare communication platform!",
  "Hi there! MediSign AI makes healthcare communication seamless for all.",
  "Welcome back! Our AI-powered translation tools are ready to help you.",
  "Hello! Begin your journey with inclusive healthcare communication.",
  "Welcome! Experience barrier-free healthcare communication today."
];

// Function to get a random fallback message
function getRandomFallbackMessage(email) {
  const messages = [
    `Welcome to MediSign AI, ${email.split('@')[0]}! Ready to break down communication barriers?`,
    `Hello ${email.split('@')[0]}! MediSign AI is here to make healthcare accessible for everyone.`,
    `Welcome back! Let's continue making communication easier, ${email.split('@')[0]}.`,
    `Great to see you, ${email.split('@')[0]}! Your accessible healthcare journey starts now.`,
    `Hi ${email.split('@')[0]}! Together, we'll make healthcare communication seamless.`
  ];
  return messages[Math.floor(Math.random() * messages.length)];
}

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
    
    let onboardingMessage = `Welcome to MediSign AI, ${email.split('@')[0]}! 🎉\n\nWe're thrilled to have you join our community. Get ready to experience healthcare communication without barriers!`;
    
    // Only try Gemini if you want to test it (will fallback on error)
    try {
      const geminiResponse = await axios.post(
        GEMINI_API_URL,
        {
          contents: [{ parts: [{ text: `Welcome new user ${email}. Generate a friendly onboarding message for a healthcare communication app.` }] }]
        },
        {
          timeout: 5000 // 5 second timeout
        }
      );
      
      if (geminiResponse?.data?.candidates?.[0]?.content?.parts?.[0]?.text) {
        onboardingMessage = geminiResponse.data.candidates[0].content.parts[0].text;
      }
    } catch (geminiError) {
      console.warn('⚠️ Gemini API not available, using fallback message:', geminiError.message);
      // Already have fallback message set above
    }
    
    await admin.firestore().collection('users').doc(uid).set({
      uid,
      email,
      role: 'user',
      onboardingMessage,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.info(`✅ Onboarding saved for ${email}`);
    return null;
  } catch (error) {
    console.error(`❌ Error in onNewUser for ${userRecord.email}:`, error.message);
    return null;
  }
});

// Callable function to get a dynamic welcome message (when user logs in)
exports.getGeminiWelcomeMessage = functions.https.onCall(async (data, context) => {
  const email = data.email;
  
  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'Email is required.');
  }
  
  let message = getRandomFallbackMessage(email);
  
  // Only try Gemini if you want to test it (will fallback on error)
  try {
    const geminiResponse = await axios.post(
      GEMINI_API_URL,
      {
        contents: [{ parts: [{ text: `Welcome back, ${email}! Generate a personalized, encouraging welcome message for a healthcare communication app user.` }] }]
      },
      {
        timeout: 5000 // 5 second timeout
      }
    );
    
    if (geminiResponse?.data?.candidates?.[0]?.content?.parts?.[0]?.text) {
      message = geminiResponse.data.candidates[0].content.parts[0].text;
    }
  } catch (geminiError) {
    console.warn('⚠️ Gemini API not available, using fallback message:', geminiError.message);
    // Already have fallback message set above
  }
  
  return { message };
});