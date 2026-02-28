import 'dart:async';
import '../../models/user_profile.dart';
import '../../data/mock_data.dart';
import 'auth_service_base.dart';

/// Mock authentication service for development and demo.
/// Uses pre-built user profiles and simulates OTP verification.
class MockAuthService implements AuthServiceBase {
  final _authController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  // Pre-built demo users
  static final UserProfile elderlyUser = MockData.elderlyUser;
  static final UserProfile caregiverUser = MockData.caregiver;
  static final UserProfile buddyUser = MockData.buddy;

  // Phone number to user mapping for sign-in
  static final Map<String, UserProfile> _phoneToUser = {
    '+60121234567': elderlyUser,
    '+60191234567': caregiverUser,
    '+60171234567': buddyUser,
  };

  @override
  Future<UserProfile?> signIn(String phone, String otp) async {
    // Simulate network delay (1 second)
    await Future.delayed(const Duration(seconds: 1));

    // Accept any OTP, match user by phone number
    final user = _phoneToUser[phone];
    if (user != null) {
      _currentUser = user;
      _authController.add(user);
      print('[MockAuth] Signed in as role: ${user.role.name}');
      return user;
    }

    // If phone number not recognized, default to elderly user
    _currentUser = elderlyUser;
    _authController.add(elderlyUser);
    print('[MockAuth] Unknown phone, defaulting to elderly user');
    return elderlyUser;
  }

  /// Quick demo login by role — bypasses phone/OTP entirely.
  Future<UserProfile> signInAs(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final user = switch (role) {
      UserRole.elderly => elderlyUser,
      UserRole.caregiver => caregiverUser,
      UserRole.buddy => buddyUser,
    };

    _currentUser = user;
    _authController.add(user);
    print('[MockAuth] Quick sign-in as role: ${role.name}');
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authController.add(null);
    print('[MockAuth] Signed out');
  }

  @override
  Stream<UserProfile?> get authStateChanges => _authController.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  /// Clean up resources.
  void dispose() {
    _authController.close();
  }
}
