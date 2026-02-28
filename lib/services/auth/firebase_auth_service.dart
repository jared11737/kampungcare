import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service_base.dart';
import '../../models/user_profile.dart';

class FirebaseAuthService implements AuthServiceBase {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  String? _verificationId;
  bool _codeSent = false;
  UserProfile? _currentUser;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Stream<UserProfile?> get authStateChanges =>
      _auth.authStateChanges().asyncMap((u) async {
        if (u == null) {
          _currentUser = null;
          return null;
        }
        final doc = await _db.collection('users').doc(u.uid).get();
        if (!doc.exists) {
          _currentUser = null;
          await _auth.signOut();
          return null;
        }
        _currentUser = UserProfile.fromJson(doc.data()!, uid: u.uid);
        return _currentUser;
      });

  @override
  Future<UserProfile?> signIn(String phone, String otp) async {
    try {
      if (_verificationId == null && !_codeSent) {
        _codeSent = true;
        await _auth.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (cred) => _auth.signInWithCredential(cred),
          verificationFailed: (e) => print('[Auth] $e'),
          codeSent: (id, _) => _verificationId = id,
          codeAutoRetrievalTimeout: (id) => _verificationId = id,
        );
        return null;
      } else if (_verificationId == null) {
        return null; // already sending, wait
      }
      final cred = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: otp);
      final result = await _auth.signInWithCredential(cred);
      _verificationId = null;
      _codeSent = false;
      if (result.user == null) return null;
      final uid = result.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        final p = UserProfile(
          uid: uid,
          name: '',
          age: 0,
          phone: phone,
          role: UserRole.elderly,
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(uid).set(p.toJson());
        _currentUser = p;
      } else {
        _currentUser = UserProfile.fromJson(doc.data()!, uid: uid);
      }
      return _currentUser;
    } catch (e) {
      print('[Auth] $e');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  @override
  Future<UserProfile?> signInAs(UserRole role) async => _currentUser;
}
