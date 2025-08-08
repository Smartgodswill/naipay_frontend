// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';



class Getuser {
  String? email;
  String? fullname;
  String? referal_count;
  String? usdt_address;
  String? usdt_balances;
  String? referal_code;
  String?mnemonic;
  List<dynamic>? usdt_transaction_history;
  Getuser({
    this.email,
    this.fullname,
    this.referal_count,
    this.usdt_address,
    this.usdt_balances,
    this.referal_code,
    this.mnemonic,
    this.usdt_transaction_history,
  });

  Getuser copyWith({
    String? email,
    String? fullname,
    String? referal_count,
    String? usdt_address,
    String? usdt_balances,
    String? referal_code,
    String? mnemonic,
    List<dynamic>? usdt_transaction_history,
  }) {
    return Getuser(
      email: email ?? this.email,
      fullname: fullname ?? this.fullname,
      referal_count: referal_count ?? this.referal_count,
      usdt_address: usdt_address ?? this.usdt_address,
      usdt_balances: usdt_balances ?? this.usdt_balances,
      referal_code: referal_code ?? this.referal_code,
      mnemonic: mnemonic ?? this.mnemonic,
      usdt_transaction_history: usdt_transaction_history ?? this.usdt_transaction_history,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'fullname': fullname,
      'referal_count': referal_count,
      'usdt_address': usdt_address,
      'usdt_balances': usdt_balances,
      'referal_code': referal_code,
      'mnemonic': mnemonic,
      'usdt_transaction_history': usdt_transaction_history,
    };
  }

  factory Getuser.fromMap(Map<String, dynamic> map) {
    return Getuser(
      email: map['email'] != null ? map['email'] as String : null,
      fullname: map['fullname'] != null ? map['fullname'] as String : null,
      referal_count: map['referal_count'] != null ? map['referal_count'] as String : null,
      usdt_address: map['usdt_address'] != null ? map['usdt_address'] as String : null,
      usdt_balances: map['usdt_balances'] != null ? map['usdt_balances'] as String : null,
      referal_code: map['referal_code'] != null ? map['referal_code'] as String : null,
      mnemonic: map['mnemonic'] != null ? map['mnemonic'] as String : null,
      usdt_transaction_history: map['usdt_transaction_history'] != null ? List<dynamic>.from((map['usdt_transaction_history'] as List<dynamic>)) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Getuser.fromJson(String source) => Getuser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Getuser(email: $email, fullname: $fullname, referal_count: $referal_count, usdt_address: $usdt_address, usdt_balances: $usdt_balances, referal_code: $referal_code,mnemonic: $mnemonic ,usdt_transaction_history: $usdt_transaction_history)';
  }

  @override
  bool operator ==(covariant Getuser other) {
    if (identical(this, other)) return true;
  
    return 
      other.email == email &&
      other.fullname == fullname &&
      other.referal_count == referal_count &&
      other.usdt_address == usdt_address &&
      other.usdt_balances == usdt_balances &&
      other.referal_code == referal_code &&
      other.mnemonic==mnemonic&&
      listEquals(other.usdt_transaction_history, usdt_transaction_history);
  }

  @override
  int get hashCode {
    return email.hashCode ^
      fullname.hashCode ^
      referal_count.hashCode ^
      usdt_address.hashCode ^
      usdt_balances.hashCode ^
      referal_code.hashCode ^
      mnemonic.hashCode ^
      usdt_transaction_history.hashCode;
  }
}
