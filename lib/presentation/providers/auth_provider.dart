import 'package:flutter/material.dart';
import 'package:spiko/core/services/auth_service.dart';
import 'package:spiko/core/services/firestore_service.dart';
import 'package:spiko/core/services/local_storage_service.dart';
import 'package:spiko/data/models/user_model.dart';
import 'package:uuid/uuid.dart';

class AuthProvider extends ChangeNotifier {
  final LocalStorageService _localStorage = LocalStorageService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool isLoading = false;
  UserModel? user;

  // Send OTP
  Future<void> sendOtp(String phone, VoidCallback onSuccess) async {
    isLoading = true;
    notifyListeners();

    await _authService.sendOtp(
      phone: phone,
      codeSent: onSuccess,
    );

    isLoading = false;
    notifyListeners();
  }

  // Verify OTP
  Future<void> verifyOtp(String otp, Function onSuccess) async {
    isLoading = true;
    notifyListeners();

    final firebaseUser = await _authService.verifyOtp(otp);

    if (firebaseUser != null) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        phone: firebaseUser.phoneNumber ?? '',
        name: "User",
        profilePic: "",
        isOnline: true,
      );

      await _firestoreService.saveUser(newUser);
      await _localStorage.saveUser(newUser);

      user = newUser;
      onSuccess();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> devLogin(String phone, Function onSuccess) async {
    isLoading = true;
    notifyListeners();

    final uid = const Uuid().v4();

    final newUser = UserModel(
      uid: uid,
      phone: phone,
      name: "User_${phone.substring(phone.length - 4)}",
      profilePic: "",
      isOnline: true,
    );

    await _firestoreService.saveUser(newUser);
    await _localStorage.saveUser(newUser);

    user = newUser;

    isLoading = false;
    notifyListeners();

    onSuccess();
  }

  Future<void> loadUser() async {
    isLoading = true;
    notifyListeners();

    final localUser = await _localStorage.getUser();

    if (localUser != null) {
      user = localUser;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _localStorage.clearUser();
    user = null;
    notifyListeners();
  }
}
