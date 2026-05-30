import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/profiles_model.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<User?> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  Future<ProfileModel?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Future<ProfileModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }
}
