import 'dart:convert';

import 'package:bodypress_flutter/core/models/ai_models.dart';
import 'package:bodypress_flutter/core/models/body_blog_entry.dart';
import 'package:bodypress_flutter/core/models/capture_entry.dart';
import 'package:bodypress_flutter/core/services/ai_service.dart';
import 'package:bodypress_flutter/core/services/journal_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A fake [AiService] that returns controlled responses.
class _FakeAiService extends AiService {
  final String? response;
  final bool shouldThrow;

  _FakeAiService({this.response, this.shouldThrow = false})
    : super(client: MockClient((_) async => http.Response('', 500)));

  @override
  Future<String> ask(
    String userPrompt, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    if (shouldThrow) {
      throw const AiServiceException('Test failure');
    }
    return response ?? '';
  }
}

void main() {
  // ─── JournalAiResult.fromJson ─────────────────────────────────────────────

  group('JournalAiResult.fromJson', () {
    test('parses all fields from valid JSON', () {
      final result = JournalAiResult.fromJson({
        'headline': 'A shining day',
        'summary': 'Great energy levels.',
        'full_body': 'Today your body danced with sunlight...',
        'mood': 'energised',
        'mood_emoji': '⚡',
        'tags': ['8k steps', 'sunny', '7h sleep'],
      });
      expect(result.headline, 'A shining day');
      expect(result.summary, 'Great energy levels.');
      expect(result.fullBody, 'Today your body danced with sunlight...');
      expect(result.mood, 'energised');
      expect(result.moodEmoji, '⚡');
      expect(result.tags, ['8k steps', 'sunny', '7h sleep']);
    });

    test('uses defaults for missing fields', () {
      final result = JournalAiResult.fromJson({});
      expect(result.headline, 'A day of quiet presence');
      expect(result.summary, '');
      expect(result.fullBody, '');
      expect(result.mood, 'calm');
      expect(result.moodEmoji, '🫀');
      expect(result.tags, isEmpty);
    });

    test('validates mood against whitelist, falls back to calm', () {
      final result = JournalAiResult.fromJson({'mood': 'EXCITED'});
      expect(result.mood, 'calm');
    });

    test('trims and lowercases mood before validation', () {
      final result = JournalAiResult.fromJson({'mood': '  Energised  '});
      expect(result.mood, 'energised');
    });

    test('all valid moods are accepted', () {
      for (final mood in [
        'energised',
        'tired',
        'active',
        'cautious',
        'rested',
        'quiet',
        'calm',
      ]) {
        final result = JournalAiResult.fromJson({'mood': mood});
        expect(result.mood, mood, reason: '$mood should be accepted');
      }
    });
  });

  // ─── JournalAiService.generate ────────────────────────────────────────────

  group('JournalAiService.generate', () {
    test('returns null when no captures and no snapshot', () async {
      final service = JournalAiService(ai: _FakeAiService());
      final result = await service.generate(DateTime.now(), []);
      expect(result, isNull);
    });

    test('returns null when snapshot has no data', () async {
      final service = JournalAiService(ai: _FakeAiService());
      final result = await service.generate(
        DateTime.now(),
        [],
        snapshotFallback: const BodySnapshot(), // all zeros / nulls
      );
      expect(result, isNull);
    });

    test('returns JournalAiResult from captures', () async {
      final aiResponse = jsonEncode({
        'headline': 'Morning run glow',
        'summary': 'A brisk morning.',
        'full_body': 'Your legs carried you through the dawn...',
        'mood': 'active',
        'mood_emoji': '🏃',
        'tags': ['5k steps', 'morning', 'clear sky'],
      });

      final service = JournalAiService(
        ai: _FakeAiService(response: aiResponse),
      );

      final captures = [
        CaptureEntry(
          id: 'c1',
          timestamp: DateTime(2025, 3, 15, 8, 0),
          healthData: const CaptureHealthData(steps: 5000, heartRate: 85),
          environmentData: const CaptureEnvironmentData(
            temperature: 12.0,
            weatherDescription: 'Clear sky',
          ),
        ),
      ];

      final result = await service.generate(DateTime(2025, 3, 15), captures);
      expect(result, isNotNull);
      expect(result!.headline, 'Morning run glow');
      expect(result.mood, 'active');
      expect(result.tags, hasLength(3));
    });

    test('returns JournalAiResult from snapshot fallback', () async {
      final aiResponse = jsonEncode({
        'headline': 'Gentle rest',
        'summary': 'A quiet day.',
        'full_body': 'Sleep came easily...',
        'mood': 'rested',
        'mood_emoji': '😴',
        'tags': ['good sleep'],
      });

      final service = JournalAiService(
        ai: _FakeAiService(response: aiResponse),
      );

      final result = await service.generate(
        DateTime(2025, 3, 15),
        [], // no captures
        snapshotFallback: const BodySnapshot(sleepHours: 8.5),
      );

      expect(result, isNotNull);
      expect(result!.mood, 'rested');
    });

    test('returns null when AI throws', () async {
      final service = JournalAiService(ai: _FakeAiService(shouldThrow: true));

      final captures = [
        CaptureEntry(
          id: 'c1',
          timestamp: DateTime(2025, 3, 15, 8, 0),
          healthData: const CaptureHealthData(steps: 1000),
        ),
      ];

      final result = await service.generate(DateTime(2025, 3, 15), captures);
      expect(result, isNull);
    });

    test('returns null when AI returns invalid JSON', () async {
      final service = JournalAiService(
        ai: _FakeAiService(response: 'not json at all'),
      );

      final captures = [
        CaptureEntry(
          id: 'c1',
          timestamp: DateTime(2025, 3, 15, 8, 0),
          healthData: const CaptureHealthData(steps: 1000),
        ),
      ];

      final result = await service.generate(DateTime(2025, 3, 15), captures);
      expect(result, isNull);
    });

    test('strips markdown fences from AI response', () async {
      final jsonContent = jsonEncode({
        'headline': 'Fenced response',
        'summary': 'Parsed correctly.',
        'full_body': 'Body text...',
        'mood': 'calm',
        'mood_emoji': '🌿',
        'tags': ['tag1'],
      });
      final fencedResponse = '```json\n$jsonContent\n```';

      final service = JournalAiService(
        ai: _FakeAiService(response: fencedResponse),
      );

      final captures = [
        CaptureEntry(
          id: 'c1',
          timestamp: DateTime(2025, 3, 15, 8, 0),
          healthData: const CaptureHealthData(steps: 500),
        ),
      ];

      final result = await service.generate(DateTime(2025, 3, 15), captures);
      expect(result, isNotNull);
      expect(result!.headline, 'Fenced response');
    });

    test('passes userNote and userMood to prompt', () async {
      String? capturedPrompt;

      final aiService = _CapturingAiService(
        aiResponse: jsonEncode({
          'headline': 'Test',
          'summary': 'S',
          'full_body': 'B',
          'mood': 'calm',
          'mood_emoji': '🌿',
          'tags': [],
        }),
        onPrompt: (p) => capturedPrompt = p,
      );

      final service = JournalAiService(ai: aiService);
      final captures = [
        CaptureEntry(
          id: 'c1',
          timestamp: DateTime(2025, 3, 15, 8, 0),
          healthData: const CaptureHealthData(steps: 1000),
        ),
      ];

      await service.generate(
        DateTime(2025, 3, 15),
        captures,
        userNote: 'Great workout!',
        userMood: '💪',
      );

      expect(capturedPrompt, contains('Great workout!'));
      expect(capturedPrompt, contains('💪'));
    });
  });
}

/// An [AiService] that captures the prompt for assertion.
class _CapturingAiService extends AiService {
  final String aiResponse;
  final void Function(String) onPrompt;

  _CapturingAiService({required this.aiResponse, required this.onPrompt})
    : super(client: MockClient((_) async => http.Response('', 500)));

  @override
  Future<String> ask(
    String userPrompt, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    onPrompt(userPrompt);
    return aiResponse;
  }
}
