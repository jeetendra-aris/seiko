class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String profilePic;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    required this.profilePic,
    required this.isOnline,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'name': name,
      'profilePic': profilePic,
      'isOnline': isOnline,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      profilePic: map['profilePic'] ?? '',
      isOnline: map['isOnline'] ?? false,
    );
  }
}
