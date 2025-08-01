// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class LoginUserModels {
  final String? email;
  final String? password;
  final String? mnemonics;
  final String? otp;
  LoginUserModels({
    this.email,
    this.password,
    this.mnemonics,
    this.otp,
  });


  LoginUserModels copyWith({
    String? email,
    String? password,
    String? mnemonics,
    String? otp,
  }) {
    return LoginUserModels(
      email: email ?? this.email,
      password: password ?? this.password,
      mnemonics: mnemonics ?? this.mnemonics,
      otp: otp ?? this.otp,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'mnemonics': mnemonics,
      'otp': otp,
    };
  }

  factory LoginUserModels.fromMap(Map<String, dynamic> map) {
    return LoginUserModels(
      email: map['email'] != null ? map['email'] as String : null,
      password: map['password'] != null ? map['password'] as String : null,
      mnemonics: map['mnemonics'] != null ? map['mnemonics'] as String : null,
      otp: map['otp'] != null ? map['otp'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LoginUserModels.fromJson(String source) => LoginUserModels.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LoginUserModels(email: $email, password: $password, mnemonics: $mnemonics, otp: $otp)';
  }

  @override
  bool operator ==(covariant LoginUserModels other) {
    if (identical(this, other)) return true;
  
    return 
      other.email == email &&
      other.password == password &&
      other.mnemonics == mnemonics &&
      other.otp == otp;
  }

  @override
  int get hashCode {
    return email.hashCode ^
      password.hashCode ^
      mnemonics.hashCode ^
      otp.hashCode;
  }
}
