import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String _chatEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _imageEndpoint = 'https://openrouter.ai/api/v1/images';
  static const String _apiKey = 'Bearer YOUR_OPENROUTER_API_KEY_HERE';
  static const String _appUrl = 'https://your-app-url.com';
  static const String _appName = 'LOVE PLUS';

  Future<String> generateText({
    required String prompt,
    String model = 'openai/gpt-4o-mini',
    double temperature = 0.7,
    double? frequencyPenalty,
    double? presencePenalty,
    Map<String, dynamic>? responseFormat,
  }) async {
    try {
      final bodyMap = <String, dynamic>{
        'model': model,
        'max_tokens': 2000,
        'temperature': temperature,
        'messages': [
          {'role': 'system', 'content': prompt}
        ],
      };
      if (frequencyPenalty != null) {
        bodyMap['frequency_penalty'] = frequencyPenalty;
      }
      if (presencePenalty != null) {
        bodyMap['presence_penalty'] = presencePenalty;
      }
      if (responseFormat != null) {
        bodyMap['response_format'] = responseFormat;
      }
      
      final response = await http.post(
        Uri.parse(_chatEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _apiKey,
          'HTTP-Referer': _appUrl,
          'X-Title': _appName,
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
        body: jsonEncode(bodyMap),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        return content?.toString().trim() ?? '';
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('JSON Parse Error');
      } else if (e.toString().contains('Timeout') || e.toString().contains('Socket')) {
        throw Exception('Network Timeout');
      }
      rethrow;
    }
  }

  Future<String?> generateImage(String prompt, {File? userPhoto, File? partnerPhoto}) async {
    try {
      String finalPrompt = "Masterpiece, highest visual quality, cinematic lighting, vivid colors, photorealistic couple photography. A breathtaking, emotional, and highly aesthetic photo of two lovers, $prompt. Shot on 35mm lens, 8k resolution, romantic mood, soft bokeh, intricate details, stunning composition. CRITICAL RULE: You must perfectly map the exact facial features from the provided reference photos to the subjects as the sole source of identity.";

      final bodyMap = <String, dynamic>{
        'model': 'bytedance-seed/seedream-4.5',
        'prompt': finalPrompt,
      };

      List<Map<String, dynamic>> inputReferences = [];

      if (userPhoto != null) {
        final bytes = await userPhoto.readAsBytes();
        inputReferences.add({
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,${base64Encode(bytes)}'
          }
        });
      }
      
      if (partnerPhoto != null) {
        final bytes = await partnerPhoto.readAsBytes();
        inputReferences.add({
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,${base64Encode(bytes)}'
          }
        });
      }

      if (inputReferences.isNotEmpty) {
        bodyMap['input_references'] = inputReferences;
      }

      final response = await http.post(
        Uri.parse(_imageEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _apiKey,
          'HTTP-Referer': _appUrl,
          'X-Title': _appName,
        },
        body: jsonEncode(bodyMap),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final imageArray = data['data'] as List<dynamic>?;
        if (imageArray == null || imageArray.isEmpty) {
          return 'Error: Received empty image data from OpenRouter API.';
        }
        
        final imageObject = imageArray[0] as Map<String, dynamic>;
        
        if (imageObject.containsKey('url') && imageObject['url'] != null) {
          return imageObject['url'].toString();
        } else if (imageObject.containsKey('b64_json') && imageObject['b64_json'] != null) {
          return 'data:image/png;base64,${imageObject['b64_json']}';
        } else {
          return 'Error: Unrecognized image output format from OpenRouter.';
        }
      } else {
        print('OpenRouter API Error: ${response.statusCode} - ${response.body}');
        return 'Error: API returned ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      print('Network connection failed: $e');
      return 'Error: Network connection failed ($e)';
    }
  }
}

