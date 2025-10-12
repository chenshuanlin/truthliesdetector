class User {
  final int? userId;
  final String account;
  final String username;
  final String password;
  final String email;
  final String? phone;

  User({
    this.userId,
    required this.account,
    required this.username,
    required this.password,
    required this.email,
    this.phone,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      account: map['account'],
      username: map['username'],
      password: map['password'],
      email: map['email'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'account': account,
      'username': username,
      'password': password,
      'email': email,
      'phone': phone,
    };
  }

  // 建立不含密碼的安全版本
  Map<String, dynamic> toSafeMap() {
    return {
      'user_id': userId,
      'account': account,
      'username': username,
      'email': email,
      'phone': phone,
    };
  }
}