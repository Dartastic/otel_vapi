// Licensed under the MIT License.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_vapi_suppression.dart';

const _tracerName = 'dartastic_otel_libs_vapi';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class VapiResult {
  const VapiResult({
    this.orgId,
    this.callId,
    this.assistantId,
    this.phoneNumberId,
    this.transport,
    this.callType,
    this.endedReason,
    this.durationSec,
    this.transcriberProvider,
    this.modelProvider,
    this.modelName,
    this.voiceProvider,
    this.modelInputTokens,
    this.modelOutputTokens,
    this.sttCost,
    this.modelCost,
    this.ttsCost,
    this.transportCost,
    this.vapiCost,
    this.totalCost,
    this.statusCode,
  });

  /// Vapi org id (multi-tenant).
  final String? orgId;

  final String? callId;
  final String? assistantId;

  /// Phone number resource (Vapi-owned, BYO Twilio, or imported).
  final String? phoneNumberId;

  /// `phone` / `web` / `vapi.websocket` / `sip` — how audio is
  /// transported.
  final String? transport;

  /// `inboundPhoneCall` / `outboundPhoneCall` / `webCall`.
  final String? callType;

  /// Why the call ended — Vapi has dozens; common values:
  /// `customer-ended-call` / `assistant-ended-call` / `silence-timed-out`
  /// / `voicemail` / `pipeline-error-*` / `customer-busy` /
  /// `customer-did-not-answer` / `phone-call-provider-closed-websocket`.
  final String? endedReason;

  final int? durationSec;

  /// `deepgram` / `talkscriber` / `gladia` / `assemblyai` / `azure`.
  final String? transcriberProvider;

  /// `openai` / `anthropic` / `groq` / `together-ai` / `xai` /
  /// `google` / `custom-llm` / `vapi`.
  final String? modelProvider;

  final String? modelName;

  /// `11labs` / `azure` / `cartesia` / `deepgram` / `lmnt` /
  /// `openai` / `playht` / `rime-ai`.
  final String? voiceProvider;

  final int? modelInputTokens;
  final int? modelOutputTokens;

  /// Cost breakdown in cents (Vapi exposes a full cost vector per
  /// call — surface each piece so you can audit which leg is
  /// expensive).
  final double? sttCost;
  final double? modelCost;
  final double? ttsCost;
  final double? transportCost;
  final double? vapiCost;
  final double? totalCost;

  final int? statusCode;
}

class VapiCallResult<T> {
  const VapiCallResult({required this.value, this.result});
  final T value;
  final VapiResult? result;
}

/// Wraps a Vapi API call in a CLIENT span. [operation] is one of
/// `call.create`, `call.get`, `call.list`, `call.end`,
/// `assistant.create`, `assistant.update`, `phone_number.buy`,
/// `phone_number.attach`, `tool.create`, `squad.create`,
/// `analytics.query`.
Future<T> tracedVapi<T>({
  required String operation,
  required Future<VapiCallResult<T>> Function() invoke,
}) async {
  if (vapiInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'vapi',
    'rpc.method': operation,
    'vapi.operation': operation,
  };

  final span = _tracer().startSpan(
    'vapi $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.orgId != null) {
        extras.add(OTelAPI.attributeString('vapi.org.id', r.result!.orgId!));
      }
      if (r.result!.callId != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.call.id',
          r.result!.callId!,
        ));
      }
      if (r.result!.assistantId != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.assistant.id',
          r.result!.assistantId!,
        ));
      }
      if (r.result!.phoneNumberId != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.phone_number.id',
          r.result!.phoneNumberId!,
        ));
      }
      if (r.result!.transport != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.transport',
          r.result!.transport!,
        ));
      }
      if (r.result!.callType != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.call.type',
          r.result!.callType!,
        ));
      }
      if (r.result!.endedReason != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.call.ended_reason',
          r.result!.endedReason!,
        ));
        if (r.result!.endedReason!.startsWith('pipeline-error') ||
            r.result!.endedReason == 'phone-call-provider-closed-websocket') {
          span.setStatus(
            SpanStatusCode.Error,
            'Vapi ended_reason ${r.result!.endedReason}',
          );
        }
      }
      if (r.result!.durationSec != null) {
        extras.add(OTelAPI.attributeInt(
          'vapi.duration_sec',
          r.result!.durationSec!,
        ));
      }
      if (r.result!.transcriberProvider != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.transcriber.provider',
          r.result!.transcriberProvider!,
        ));
      }
      if (r.result!.modelProvider != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.model.provider',
          r.result!.modelProvider!,
        ));
      }
      if (r.result!.modelName != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.model.name',
          r.result!.modelName!,
        ));
      }
      if (r.result!.voiceProvider != null) {
        extras.add(OTelAPI.attributeString(
          'vapi.voice.provider',
          r.result!.voiceProvider!,
        ));
      }
      if (r.result!.modelInputTokens != null) {
        extras.add(OTelAPI.attributeInt(
          'vapi.model.input_tokens',
          r.result!.modelInputTokens!,
        ));
      }
      if (r.result!.modelOutputTokens != null) {
        extras.add(OTelAPI.attributeInt(
          'vapi.model.output_tokens',
          r.result!.modelOutputTokens!,
        ));
      }
      if (r.result!.sttCost != null) {
        extras.add(OTelAPI.attributeDouble(
          'vapi.cost.stt',
          r.result!.sttCost!,
        ));
      }
      if (r.result!.modelCost != null) {
        extras.add(OTelAPI.attributeDouble(
          'vapi.cost.model',
          r.result!.modelCost!,
        ));
      }
      if (r.result!.ttsCost != null) {
        extras.add(OTelAPI.attributeDouble(
          'vapi.cost.tts',
          r.result!.ttsCost!,
        ));
      }
      if (r.result!.transportCost != null) {
        extras.add(OTelAPI.attributeDouble(
          'vapi.cost.transport',
          r.result!.transportCost!,
        ));
      }
      if (r.result!.vapiCost != null) {
        extras.add(OTelAPI.attributeDouble(
          'vapi.cost.vapi',
          r.result!.vapiCost!,
        ));
      }
      if (r.result!.totalCost != null) {
        extras.add(OTelAPI.attributeDouble(
          'vapi.cost.total',
          r.result!.totalCost!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Vapi HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
