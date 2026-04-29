import 'package:supabase_flutter/supabase_flutter.dart';

/// SupabaseService provides a centralized interface for Supabase operations
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() {
    return _instance;
  }
  
  SupabaseService._internal();
  
  SupabaseClient get client => Supabase.instance.client;
  
  /// Get current user
  User? get currentUser => client.auth.currentUser;
  
  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }
  
  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUser == null) {
      throw Exception('No user logged in');
    }
    
    await client.from('profiles').update(updates).eq('id', currentUser!.id);
  }
  
  /// Fetch user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return response as Map<String, dynamic>?;
  }
  
  /// Insert data into a table
  Future<List<Map<String, dynamic>>> insert(String table, Map<String, dynamic> data) async {
    final response = await client.from(table).insert(data).select();
    return response as List<Map<String, dynamic>>;
  }
  
  /// Update data in a table
  Future<List<Map<String, dynamic>>> update(
    String table, 
    Map<String, dynamic> data, 
    String column, 
    dynamic value
  ) async {
    final response = await client.from(table).update(data).eq(column, value).select();
    return response as List<Map<String, dynamic>>;
  }
  
  /// Delete data from a table
  Future<void> delete(String table, String column, dynamic value) async {
    await client.from(table).delete().eq(column, value);
  }
  
  /// Select data from a table
  Future<List<Map<String, dynamic>>> select(String table, {String? columns}) async {
    var query = client.from(table).select(columns ?? '*');
    final response = await query;
    return response as List<Map<String, dynamic>>;
  }
  
  /// Select single record from a table
  Future<Map<String, dynamic>?> selectSingle(String table, String column, dynamic value) async {
    final response = await client.from(table).select().eq(column, value).single();
    return response as Map<String, dynamic>?;
  }
  
  /// Stream real-time changes
  Stream<List<Map<String, dynamic>>> stream(String table) {
    return client.from(table).stream(primaryKey: ['id']).map((event) {
      return event.map((e) => e as Map<String, dynamic>).toList();
    });
  }
}
