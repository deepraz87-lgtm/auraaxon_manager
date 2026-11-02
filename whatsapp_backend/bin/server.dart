import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import '../lib/env.dart';

import '../lib/database.dart';
import '../lib/whatsapp_service.dart';
import '../lib/gemini_service.dart';

// Configure routes
final _router = Router()
  ..get('/api/whatsapp-webhook', _verifyWebhook)
  ..post('/api/whatsapp-webhook', _handleIncomingMessage);

// Webhook Verification (GET)
Response _verifyWebhook(Request request) {
  final queryParams = request.url.queryParameters;

  final mode = queryParams['hub.mode'];
  final token = queryParams['hub.verify_token'];
  final challenge = queryParams['hub.challenge'];

  final verifyToken = env['WHATSAPP_VERIFY_TOKEN'];

  if (mode != null && token != null) {
    if (mode == 'subscribe' && token == verifyToken) {
      print('WEBHOOK_VERIFIED');
      return Response.ok(challenge);
    } else {
      return Response.forbidden('Forbidden');
    }
  }

  return Response.badRequest(body: 'Bad Request');
}

// Message Reception (POST)
Future<Response> _handleIncomingMessage(Request request) async {
  try {
    final payloadString = await request.readAsString();
    final payload = jsonDecode(payloadString);

    if (payload['object'] == 'whatsapp_business_account') {
      for (var entry in payload['entry']) {
        for (var change in entry['changes']) {
          final value = change['value'];

          if (value['messages'] != null && value['messages'].isNotEmpty) {
            final messageObj = value['messages'][0];
            final contactObj = value['contacts']?[0];

            // Extract required data
            final phoneNumber = messageObj['from'];
            final profileName = contactObj?['profile']?['name'];
            final messageText = messageObj['text']?['body'];

            if (phoneNumber != null && messageText != null) {
              print('Received message from $phoneNumber: $messageText');

              // 1. Save or Update Lead in Database
              await DatabaseHelper.saveOrUpdateLead(
                phoneNumber,
                profileName,
                messageText,
              );

              // 2. Generate AI Response
              final aiResponse = await GeminiService.generateResponse(
                messageText,
              );

              // 3. Send Reply via WhatsApp Cloud API
              await WhatsAppService.sendReply(phoneNumber, aiResponse);
            }
          }
        }
      }
      return Response.ok('EVENT_RECEIVED');
    } else {
      return Response.notFound('Not Found');
    }
  } catch (e) {
    print('Error processing webhook: $e');
    return Response.internalServerError(body: 'Internal Server Error');
  }
}

void main(List<String> args) async {
  // Environment variables are loaded in lib/env.dart
  var envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Warning: .env file not found.');
  }

  // Use any available host or IPv4 accept all
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable
  final port = int.parse(Platform.environment['PORT'] ?? env['PORT'] ?? '8080');

  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
