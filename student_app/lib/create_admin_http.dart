import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://phajvgasogyqzfyfvlyh.supabase.co/auth/v1/signup');
  final headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBoYWp2Z2Fzb2d5cXpmeWZ2bHloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc2MTM1MzUsImV4cCI6MjA4MzE4OTUzNX0.ie-LzlUK4IJ8XqKvPD1VAtqXoh8U2p2kVwLSV3pfB44',
    'Content-Type': 'application/json',
  };
  final body = jsonEncode({
    'email': 'kkarynossang@gmail.com',
    'password': 'no850413',
  });

  try {
    final response = await http.post(url, headers: headers, body: body);
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
