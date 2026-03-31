import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;

  // Send OTP
  Future<void> sendOtp({
    required String phone,
    required Function() codeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: "+91$phone",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Error: ${e.message}");
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        codeSent();
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  // Verify OTP
  Future<User?> verifyOtp(String otp) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    return userCredential.user;
  }

  User? get currentUser => _auth.currentUser;

  Future<void> logout() async {
    await _auth.signOut();
  }
}
