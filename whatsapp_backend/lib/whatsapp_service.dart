import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env.dart';

class WhatsAppService {
  static Future<void> sendReply(String toPhoneNumber, String message) async {
    final token = env['WHATSAPP_ACCESS_TOKEN'];
    final phoneNumberId = env['WHATSAPP_PHONE_NUMBER_ID'];

    if (token == null || phoneNumberId == null) {
      print('Error: WhatsApp credentials not configured.');
      return;
    }

    final url = Uri.parse('https://graph.facebook.com/v17.0/$phoneNumberId/messages');
    
    final payload = {
      'messaging_product': 'whatsapp',
      'to': toPhoneNumber,
      'type': 'text',
      'text': {
        'body': message,
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('Message sent successfully to $toPhoneNumber');
      } else {
        print('Failed to send message: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Exception while sending WhatsApp message: $e');
    }
  }
}
