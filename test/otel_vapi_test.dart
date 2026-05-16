// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_vapi/otel_vapi.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_vapi-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('call.create records full cost vector + providers', () async {
    await tracedVapi<String>(
      operation: 'call.create',
      invoke: () async => const VapiCallResult(
        value: 'ok',
        result: VapiResult(
          orgId: 'org_1',
          callId: 'c_1',
          assistantId: 'a_1',
          transport: 'phone',
          callType: 'outboundPhoneCall',
          endedReason: 'customer-ended-call',
          durationSec: 180,
          transcriberProvider: 'deepgram',
          modelProvider: 'openai',
          modelName: 'gpt-4o',
          voiceProvider: '11labs',
          modelInputTokens: 8500,
          modelOutputTokens: 1200,
          sttCost: 0.012,
          modelCost: 0.045,
          ttsCost: 0.090,
          transportCost: 0.022,
          vapiCost: 0.015,
          totalCost: 0.184,
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('vapi call.create')!);
    expect(a['vapi.transport'], 'phone');
    expect(a['vapi.call.type'], 'outboundPhoneCall');
    expect(a['vapi.model.provider'], 'openai');
    expect(a['vapi.voice.provider'], '11labs');
    expect(a['vapi.cost.tts'], 0.090);
    expect(a['vapi.cost.total'], 0.184);
  });

  test('pipeline-error ended_reason sets span error', () async {
    await tracedVapi<String>(
      operation: 'call.get',
      invoke: () async => const VapiCallResult(
        value: 'ok',
        result: VapiResult(
          endedReason: 'pipeline-error-openai-llm-failed',
          durationSec: 12,
        ),
      ),
    );
    expect(
      spans.findSpanByName('vapi call.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('voicemail ended_reason does NOT set span error', () async {
    await tracedVapi<String>(
      operation: 'call.get',
      invoke: () async => const VapiCallResult(
        value: 'ok',
        result: VapiResult(endedReason: 'voicemail', durationSec: 8),
      ),
    );
    expect(
      spans.findSpanByName('vapi call.get')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutVapiInstrumentationAsync(() async {
      await tracedVapi<String>(
        operation: 'assistant.create',
        invoke: () async => const VapiCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('vapi '), isEmpty);
  });
}
