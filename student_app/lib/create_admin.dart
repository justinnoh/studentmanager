import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://phajvgasogyqzfyfvlyh.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBoYWp2Z2Fzb2d5cXpmeWZ2bHloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc2MTM1MzUsImV4cCI6MjA4MzE4OTUzNX0.ie-LzlUK4IJ8XqKvPD1VAtqXoh8U2p2kVwLSV3pfB44',
  );

  try {
    final response = await client.auth.signUp(
      email: 'kkarynossang@gmail.com',
      password: 'no850413',
    );
    print('User created: ${response.user?.id}');
  } catch (e) {
    print('Error: $e');
  }
}
