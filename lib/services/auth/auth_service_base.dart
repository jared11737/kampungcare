import '../../models/user_profile.dart';

abstract class AuthServiceBase {
  Future<UserProfile?> signIn(String phone, String otp);
  Future<void> signOut();
  Future<UserProfile?> signInAs(UserRole role);
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;
}
