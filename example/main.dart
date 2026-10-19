// Licensed under the MIT License.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_vapi/otel_vapi.dart';

/// Traces Vapi calls with OpenTelemetry.
///
/// `otel_vapi` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Vapi call in
/// [tracedVapi]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'vapi-example');

  // Wraps a Vapi API call in a CLIENT span.
  final vapiId = await tracedVapi<String>(
    operation: 'call.create',
    invoke: () async {
      // Make the Vapi call here, then report what it returned.
      const id = 'vapi_8f3a2c';
      return const VapiCallResult(
          value: id,
          result: VapiResult(
              orgId: 'org_8f3a2c',
              callId: 'call_8f3a2c',
              assistantId: 'assistant_8f3a2c',
              phoneNumberId: 'phonenumber_8f3a2c',
              transport: 'phone',
              callType: 'inboundPhoneCall',
              endedReason: 'customer-ended-call',
              durationSec: 120,
              transcriberProvider: 'deepgram',
              modelProvider: 'openai',
              modelName: 'standard',
              voiceProvider: '11labs',
              modelInputTokens: 128,
              modelOutputTokens: 128,
              sttCost: 0.5,
              modelCost: 0.5,
              ttsCost: 0.5,
              transportCost: 0.5,
              vapiCost: 0.5,
              totalCost: 0.5,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedVapi call.create returned $vapiId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutVapiInstrumentationAsync.
  await runWithoutVapiInstrumentationAsync(
    () => tracedVapi<String>(
      operation: 'call.create',
      invoke: () async {
        const id = 'vapi_8f3a2c';
        return const VapiCallResult(
            value: id,
            result: VapiResult(
                orgId: 'org_8f3a2c',
                callId: 'call_8f3a2c',
                assistantId: 'assistant_8f3a2c',
                phoneNumberId: 'phonenumber_8f3a2c',
                transport: 'phone',
                callType: 'inboundPhoneCall',
                endedReason: 'customer-ended-call',
                durationSec: 120,
                transcriberProvider: 'deepgram',
                modelProvider: 'openai',
                modelName: 'standard',
                voiceProvider: '11labs',
                modelInputTokens: 128,
                modelOutputTokens: 128,
                sttCost: 0.5,
                modelCost: 0.5,
                ttsCost: 0.5,
                transportCost: 0.5,
                vapiCost: 0.5,
                totalCost: 0.5,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
