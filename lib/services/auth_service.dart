import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../database/database_helper.dart';
import 'background_sync_service.dart';

/// Authentication service for user login, signup, and session management
/// Uses Supabase Auth for secure authentication
class AuthService {
  /// Register new user with email and password
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        print('✅ User registered: ${response.user!.email}');
      }
      
      return response;
    } catch (e) {
      print('❌ Sign up error: $e');
      rethrow;
    }
  }
  
  /// Login existing user with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        print('✅ User logged in: ${response.user!.email}');
      }
      
      return response;
    } catch (e) {
      print('❌ Sign in error: $e');
      rethrow;
    }
  }
  
  /// Logout current user and clear local data
  Future<void> signOut() async {
    try {
      // CRITICAL: Stop background sync FIRST to prevent race conditions
      // This prevents background sync from uploading empty data during logout
      print('🛑 Stopping background sync...');
      BackgroundSyncService().stopBackgroundSync();
      
      // Clear all local data (prevent data leakage)
      print('🗑️ Clearing local data...');
      await DatabaseHelper().clearAllData();
      
      // Then sign out from Supabase
      await supabase.auth.signOut();
      print('✅ User logged out and local data cleared');
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow;
    }
  }
  
  /// Get current user
  User? get currentUser => supabase.auth.currentUser;
  
  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;
  
  /// Get user ID (for database queries)
  String? get userId => currentUser?.id;
  
  /// Get user email
  String? get userEmail => currentUser?.email;
  
  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
  
  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      print('✅ Password reset email sent to: $email');
    } catch (e) {
      print('❌ Password reset error: $e');
      rethrow;
    }
  }
  
  /// Update user password (when logged in)
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      print('✅ Password updated');
      return response;
    } catch (e) {
      print('❌ Update password error: $e');
      rethrow;
    }
  }
  
  /// Check if session is valid (not expired)
  bool get hasValidSession {
    final session = supabase.auth.currentSession;
    if (session == null) return false;
    
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    
    return DateTime.now().isBefore(
      DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
    );
  }
  
  /// Get current access token (for API calls)
  String? get accessToken => supabase.auth.currentSession?.accessToken;
}
