import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  GeminiService._();

  static final GeminiService instance = GeminiService._();
  static const String _defaultModel = 'gemini-2.5-flash';
  static const String _fallbackModel = 'gemini-2.5-pro';
  static const String _apiBase =
      'https://generativelanguage.googleapis.com/v1/models';

  Future<String> generateFeedback({
    required String personName,
    required String personActivity,
    required String userReflection,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw const GeminiException('Gemini API Key가 설정되지 않았습니다.');
    }

    final configuredModel =
        dotenv.env['GEMINI_MODEL']?.trim();
    final modelsToTry = <String>[
      configuredModel?.isNotEmpty == true
          ? configuredModel!
          : _defaultModel,
      if (configuredModel == null ||
          configuredModel != _fallbackModel)
        _fallbackModel,
    ];

    final prompt = _buildPrompt(personName, personActivity, userReflection);
    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    for (final model in modelsToTry) {
      final uri = Uri.parse('$_apiBase/$model:generateContent?key=$apiKey');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final text = _extractText(response.body);
        if (text != null && text.isNotEmpty) {
          return text;
        }
        throw const GeminiException('응답이 비어 있습니다.');
      }

      debugPrint(
          'Gemini error for model $model: ${response.statusCode} ${response.body}');

      if (response.statusCode != 404) {
        throw GeminiException(
            '피드백을 생성하지 못했습니다. (${response.statusCode})');
      }
    }

    throw const GeminiException('사용 가능한 모델을 찾지 못했습니다.');
  }

  String _buildPrompt(
    String personName,
    String activity,
    String reflection,
  ) {
    return '''
당신은 멘탈 코치입니다. 아래 정보를 바탕으로 3가지 섹션을 만들어 주세요.
1) 오늘 $personName 의 활동 요약
2) 내 감상에 대한 공감과 피드백
3) 내가 내일 시도하면 좋을 실천 아이디어 2가지

- 말투는 따뜻하고 존중하는 어조 사용
- 각 섹션은 짧은 제목과 1-2문장 설명으로 구성
- 한국어로 답변

오늘의 대상 활동: "$activity"
나의 감상: "$reflection"
''';
  }

  String? _extractText(String rawBody) {
    final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
    final candidates = decoded['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final content = candidates.first['content'];
      if (content is Map<String, dynamic>) {
        final parts = content['parts'];
        if (parts is List && parts.isNotEmpty) {
          final text = parts.first['text'];
          if (text is String) {
            return text.trim();
          }
        }
      }
    }
    return null;
  }
}

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => message;
}

final GeminiService geminiService = GeminiService.instance;
