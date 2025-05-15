import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:js' as js;

/// A simplified Gemini chat client that tries a few specific models directly
class GeminiChatClient {
  // Store last successful model to optimize future requests
  static String? _lastSuccessfulModel;
  
  // Get API key from JavaScript bridge
  String get _apiKey {
    try {
      return js.context['GEMINI_API_KEY'] as String;
    } catch (e) {
      print('❌ Error accessing API key from JavaScript: $e');
      return '';
    }
  }

  // List of models to try in order of preference
  final List<Map<String, String>> _modelsToTry = [
    {
      'name': '2.5-flash-preview-0417',
      'endpoint': 'https://generativelanguage.googleapis.com/beta/models/gemini-2.5-flash-preview:generateContent',
      'apiVersion': 'v1beta'
    },
    {
      'name': 'gemini-2.5-pro-preview-0506',
      'endpoint': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-preview:generateContent',
      'apiVersion': 'v1beta'
    },
    {
      'name': 'gemini-2.0-flash',
      'endpoint': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      'apiVersion': 'v1beta'
    },
    {
      'name': 'gemini-2.0-flash',
      'endpoint': 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent',
      'apiVersion': 'v1'
    }
  ];

  /// Sends [userInput] to Gemini API directly
  Future<String> send(String userInput) async {
    final systemPrompt = '''
👩‍⚕️ You are MedisignAI, an empathetic, HIPAA-compliant medical assistant serving global users.

## Medical Domains:
• **Minor ailments**: Triage headaches, colds, fevers, digestive upsets, allergies, minor burns, cuts, sprains, and skin rashes.
• **Major conditions**: Counsel on diabetes, hypertension, heart disease, cancer, autoimmune disorders, kidney disease, and liver conditions.
• **Infectious diseases**: Advise on COVID-19, influenza, dengue, malaria, tuberculosis, hepatitis, HIV/AIDS (preventive information only), and zoonotic diseases.
• **Mental health**: Support for depression, anxiety, stress management, sleep hygiene, PTSD, bipolar disorder, ADHD, and eating disorders.
• **Women's health**: Menstruation concerns, pregnancy symptoms, menopause, contraception options, and breast health awareness.
• **Men's health**: Prostate health, testicular self-exams, erectile dysfunction general information, and testosterone-related concerns.
• **Pediatric concerns**: Common childhood illnesses, developmental milestones, vaccination schedules, nutrition for growing children, and adolescent health.
• **Geriatric care**: Fall prevention, memory concerns, medication management tips, and maintaining independence.
• **Preventive care**: Vaccinations, screenings, lifestyle modifications, nutrition guidance, and exercise recommendations.
• **Chronic pain**: General management strategies, non-pharmacological approaches, and when to seek specialized care.
• **Digestive health**: IBS, GERD, Crohn's, ulcerative colitis, and common digestive symptoms.
• **Respiratory conditions**: Asthma, COPD, seasonal allergies, bronchitis, and breathing exercises.
• **Dermatological issues**: Common skin conditions, basic skincare advice, sun protection, and when to see a dermatologist.
• **Neurological concerns**: Headache types, vertigo, seizure first aid, and stroke warning signs.
• **Endocrine disorders**: Thyroid conditions, adrenal issues, and hormonal imbalances.
• **Oral health**: Basic dental hygiene, common dental problems, and preventive care.
• **Eye conditions**: Common vision problems, eye infection signs, and eye strain prevention.
• **Travel health**: General guidance on vaccinations, common travel risks, jet lag management, and traveler's diarrhea prevention.
• **Environmental & occupational**: Air pollution protection, heat/cold stress, ergonomic advice, and workplace health tips.
• **Nutritional guidance**: Balanced diet recommendations, food allergies/intolerances, special dietary needs, and nutritional deficiencies.
• **Physical activity**: Exercise recommendations for different age groups and conditions, injury prevention, and rehabilitation basics.
• **Sleep health**: Sleep hygiene practices, common sleep disorders, and healthy sleep patterns.
• **Substance use**: Information about tobacco, alcohol, caffeine effects, and substance use harm reduction.
• **Alternative/complementary approaches**: Overview of evidence-based complementary therapies, meditation, acupuncture, and herbal medicine facts.
• **Emergency recognition**: Help identify true medical emergencies requiring immediate care.
• **Medication guidance**: General information about common medication classes, adherence importance, and potential interactions.
• **Surgical preparation**: General pre-operative and post-operative care guidance.
• **Rehabilitation**: Basic advice for recovery from injuries, surgeries, or acute conditions.
• **Rare diseases**: Listen carefully to symptoms of rare conditions and suggest specialist evaluation.
• **Immune system health**: Immunodeficiencies, autoimmune conditions, and immune system support.
• **Palliative care**: General comfort measures and quality of life considerations for serious illnesses.
• **Genetic conditions**: Basic information about hereditary conditions and when genetic counseling might be appropriate.
• **Reproductive health**: Fertility awareness, sexual health education, and STI prevention information.
• **Post-discharge care**: General guidance for recovery after hospital stays.
• **Health literacy**: Explain medical terms in simple language and help interpret basic medical information.
• **Accessibility needs**: Provide accommodations for users with disabilities or language barriers.
• **Cultural sensitivity**: Respect cultural differences in health beliefs and practices.
• **LGBTQ+ health**: Inclusive care information addressing specific health concerns.

## Response Guidelines:
• Always **recommend appropriate specialists** when needed (e.g., cardiologist, dermatologist, psychiatrist, etc.).
• Suggest **common treatments or medications** (OTC and general classes of prescriptions) without prescribing.
• For serious symptoms, **emphasize the importance of urgent medical attention**.
• Provide **lifestyle modification suggestions** when appropriate.
• Include **preventive care recommendations** relevant to the user's concern.
• Offer **reliable self-care strategies** for managing symptoms.
• **Acknowledge uncertainty** when information is incomplete.
• **Respect patient autonomy** while providing evidence-based guidance.
• **Adapt communication style** based on health literacy level.
• **Prioritize critical information** for emergency situations.
• **Note important warning signs** that require medical follow-up.
• **Emphasize continuity of care** for chronic conditions.
• **Consider geographic differences** in healthcare access and resources.
• **Be mindful of socioeconomic factors** affecting health decisions.

## Important Disclaimers:
• Begin responses with: "👩‍⚕️ MedisignAI here!"
• End responses with: "⚠️ Disclaimer: I am not a doctor; please consult a qualified healthcare professional for diagnosis and treatment."
• Use a **warm, interactive tone** with appropriate emojis to reassure and engage users worldwide.
• **Do not diagnose** specific conditions, but help users understand possible causes of symptoms.
• **Clearly state limitations** of AI-based medical assistance.
• **Encourage professional medical consultation** for all significant health concerns.
''';

    try {
      // Standard payload structure that works with most models
      final payload = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              { 'text': systemPrompt },
              { 'text': userInput }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'candidateCount': 1,
          'maxOutputTokens': 2048
        }
      };

      // Try each model in the list until one works
      // If we have a previously successful model, try that first
      final modelsToTry = List<Map<String, String>>.from(_modelsToTry);
      if (_lastSuccessfulModel != null) {
        // Move the last successful model to the front of the list
        final lastSuccessfulIndex = modelsToTry.indexWhere((model) => model['name'] == _lastSuccessfulModel);
        if (lastSuccessfulIndex >= 0) {
          final lastSuccessfulModel = modelsToTry.removeAt(lastSuccessfulIndex);
          modelsToTry.insert(0, lastSuccessfulModel);
          print('🔄 Prioritizing last successful model: $_lastSuccessfulModel');
        }
      }
      
      for (final model in modelsToTry) {
        try {
          print('🧪 Trying model: ${model['name']}');
          
          final endpoint = '${model['endpoint']}?key=$_apiKey';
          final response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 5)); // Reduce timeout to 5 seconds to match expected load time
          
          if (response.statusCode == 200) {
            print('✅ Success with model: ${model['name']}');
            
            final jsonResponse = jsonDecode(response.body);
            String? reply;
            
            // Try to parse based on API version
            if (model['apiVersion'] == 'v1beta') {
              reply = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
            } else {
              reply = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
                     jsonResponse['candidates']?[0]?['text'] ??
                     jsonResponse['response']?['text'];
            }
            
            if (reply != null && reply.trim().isNotEmpty) {
              // Remember this successful model for future requests
              _lastSuccessfulModel = model['name'];
              return reply.trim();
            }
          } else {
            print('⚠️ Model ${model['name']} failed: (${response.statusCode}) - ${response.body}');
          }
        } catch (e) {
          print('⚠️ Error with model ${model['name']}: $e');
          // Continue to next model
        }
      }
      
      // If all models fail, return mock response
      print('❌ All models failed, using mock response');
      return _getMockResponse(userInput);
    } catch (e) {
      print('❌ Fatal error: $e');
      return _getMockResponse(userInput);
    }
  }
  
  /// Generate a basic mock response when API calls fail
  String _getMockResponse(String userInput) {
    // Convert input to lowercase for easier matching
    final input = userInput.toLowerCase();
    
    // Check for common health keywords
    if (input.contains('headache')) {
      return '''👩‍⚕️ MedisignAI here!

I understand you're dealing with a headache. This could be due to various reasons like stress, dehydration, lack of sleep, or eyestrain.

Try these steps:
• Drink water - dehydration is a common cause
• Take a break from screens
• Rest in a quiet, dark room
• Try over-the-counter pain relievers like acetaminophen or ibuprofen if appropriate
• Apply a cold or warm compress to your forehead or neck

If your headache is severe, sudden, or accompanied by fever, confusion, stiff neck, or vision changes, please seek medical attention immediately.

⚠️ Disclaimer: I am not a doctor; please consult a qualified healthcare professional for diagnosis and treatment.''';
    } else if (input.contains('cold') || input.contains('flu') || input.contains('sick')) {
      return '''👩‍⚕️ MedisignAI here!

Sorry to hear you're feeling unwell. For cold or flu symptoms, focus on rest and recovery:
• Stay hydrated with plenty of fluids
• Get extra rest
• Use over-the-counter medications for symptom relief if appropriate
• Use a humidifier to ease congestion
• Try warm liquids like tea with honey for sore throat

If you experience high fever (above 101.3°F/38.5°C), difficulty breathing, chest pain, or symptoms that worsen after improving, please seek medical attention.

⚠️ Disclaimer: I am not a doctor; please consult a qualified healthcare professional for diagnosis and treatment.''';
    } else if (input.contains('pain')) {
      return '''👩‍⚕️ MedisignAI here!

I'm sorry to hear you're experiencing pain. Here are some general recommendations:
• Rest the affected area if possible
• Apply ice for acute pain (first 48 hours) to reduce inflammation
• Apply heat for chronic pain to improve blood flow
• Try over-the-counter pain relievers if appropriate
• Consider gentle stretching for muscle pain (if not acute injury)

Seek immediate medical attention if:
• Pain is severe or unbearable
• Pain is accompanied by fever, redness, or swelling
• Pain follows an injury
• You experience chest pain or difficulty breathing
• You have abdominal pain that is severe or accompanied by vomiting

⚠️ Disclaimer: I am not a doctor; please consult a qualified healthcare professional for diagnosis and treatment.''';
    } else {
      return '''👩‍⚕️ MedisignAI here!

Thank you for your message. I'd be happy to help with your health question.

For general health maintenance:
• Stay hydrated with plenty of water throughout the day
• Eat a balanced diet rich in fruits, vegetables, whole grains, and lean proteins
• Get regular physical activity - aim for at least 150 minutes of moderate exercise per week
• Ensure adequate sleep (7-9 hours for most adults)
• Manage stress through relaxation techniques like deep breathing or meditation
• Stay up to date with recommended preventive screenings and vaccinations

If you have specific health concerns, please provide more details so I can offer more tailored information.

⚠️ Disclaimer: I am not a doctor; please consult a qualified healthcare professional for diagnosis and treatment.''';
    }
  }
}