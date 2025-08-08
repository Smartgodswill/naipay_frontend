// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';

class LoginUserModels {
  final String? email;
  final String? password;
  final String? mnemonics;
  final String? otp;
  final String?usdtAddress;
  final String?usdtBalances;
  final List<dynamic>? usdtTransactionHistory;
  LoginUserModels( {
    this.email,
    this.password,
    this.mnemonics,
    this.otp,
    this.usdtAddress,
     this.usdtBalances,
    this.usdtTransactionHistory,
  });

  LoginUserModels copyWith({
    String? email,
    String? password,
    String? mnemonics,
    String? otp,
    List<dynamic>? usdtTransactionHistory,
  }) {
    return LoginUserModels(
      email: email ?? this.email,
      password: password ?? this.password,
      mnemonics: mnemonics ?? this.mnemonics,
      otp: otp ?? this.otp,
      usdtTransactionHistory: usdtTransactionHistory ?? this.usdtTransactionHistory,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'mnemonics': mnemonics,
      'otp': otp,
      'usdtTransactionHistory': usdtTransactionHistory,
    };
  }

  factory LoginUserModels.fromMap(Map<String, dynamic> map) {
    return LoginUserModels(
      email: map['email'] != null ? map['email'] as String : null,
      password: map['password'] != null ? map['password'] as String : null,
      mnemonics: map['mnemonics'] != null ? map['mnemonics'] as String : null,
      otp: map['otp'] != null ? map['otp'] as String : null,
      usdtTransactionHistory: map['usdtTransactionHistory'] != null ? List<dynamic>.from((map['usdtTransactionHistory'] as List<dynamic>)) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LoginUserModels.fromJson(String source) => LoginUserModels.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LoginUserModels(email: $email, password: $password, mnemonics: $mnemonics, otp: $otp, usdtTransactionHistory: $usdtTransactionHistory)';
  }

  @override
  bool operator ==(covariant LoginUserModels other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;
  
    return 
      other.email == email &&
      other.password == password &&
      other.mnemonics == mnemonics &&
      other.otp == otp &&
      listEquals(other.usdtTransactionHistory, usdtTransactionHistory);
  }

  @override
  int get hashCode {
    return email.hashCode ^
      password.hashCode ^
      mnemonics.hashCode ^
      otp.hashCode ^
      usdtTransactionHistory.hashCode;
  }
}
