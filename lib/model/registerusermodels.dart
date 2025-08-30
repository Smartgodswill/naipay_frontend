// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names

import 'dart:convert';

class User {
  String? fullname;
  String? email;
  String? country;
  String? password;
  String? referred_by;
  String? otp;
  String? bitcoin_descriptor;
  User({
    this.fullname,
    this.email,
    this.country,
    this.password,
    this.referred_by,
    this.otp,
    this.bitcoin_descriptor,
  });

  User copyWith({
    String? fullname,
    String? email,
    String? country,
    String? password,
    String? referred_by,
    String? otp,
    String? bitcoin_descriptor,
  }) {
    return User(
      fullname: fullname ?? this.fullname,
      email: email ?? this.email,
      country: country ?? this.country,
      password: password ?? this.password,
      referred_by: referred_by ?? this.referred_by,
      otp: otp ?? this.otp,
      bitcoin_descriptor: bitcoin_descriptor ?? this.bitcoin_descriptor,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fullname': fullname,
      'email': email,
      'country': country,
      'password': password,
      'referred_by': referred_by,
      'otp': otp,
      'bitcoin_descriptor': bitcoin_descriptor,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      fullname: map['fullname'] != null ? map['fullname'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      country: map['country'] != null ? map['country'] as String : null,
      password: map['password'] != null ? map['password'] as String : null,
      referred_by: map['referred_by'] != null ? map['referred_by'] as String : null,
      otp: map['otp'] != null ? map['otp'] as String : null,
      bitcoin_descriptor: map['bitcoin_descriptor'] != null ? map['bitcoin_descriptor'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(fullname: $fullname, email: $email, country: $country, password: $password, referred_by: $referred_by, otp: $otp, bitcoin_descriptor: $bitcoin_descriptor)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;
  
    return 
      other.fullname == fullname &&
      other.email == email &&
      other.country == country &&
      other.password == password &&
      other.referred_by == referred_by &&
      other.otp == otp &&
      other.bitcoin_descriptor == bitcoin_descriptor;
  }

  @override
  int get hashCode {
    return fullname.hashCode ^
      email.hashCode ^
      country.hashCode ^
      password.hashCode ^
      referred_by.hashCode ^
      otp.hashCode ^
      bitcoin_descriptor.hashCode;
  }
}
