import 'dart:convert';

import 'package:flutter/foundation.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first


class Walletmodel {
   String? email;
   String? bitcoin_address;
   String? bitcoin_descriptor;
   String? mnemonic;
   int? balance_sats;
  List<dynamic>? transaction_history;
  Walletmodel({
    this.email,
    this.bitcoin_address,
    this.bitcoin_descriptor,
    this.mnemonic,
    this.balance_sats,
    this.transaction_history,
  });

  Walletmodel copyWith({
    String? email,
    String? bitcoin_address,
    String? bitcoin_descriptor,
    String? mnemonic,
    int? balance_sats,
    List<dynamic>? transaction_history,
  }) {
    return Walletmodel(
      email: email ?? this.email,
      bitcoin_address: bitcoin_address ?? this.bitcoin_address,
      bitcoin_descriptor: bitcoin_descriptor ?? this.bitcoin_descriptor,
      mnemonic: mnemonic ?? this.mnemonic,
      balance_sats: balance_sats ?? this.balance_sats,
      transaction_history: transaction_history ?? this.transaction_history,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'bitcoin_address': bitcoin_address,
      'bitcoin_descriptor': bitcoin_descriptor,
      'mnemonic': mnemonic,
      'balance_sats': balance_sats,
      'transaction_history': transaction_history,
    };
  }

  factory Walletmodel.fromMap(Map<String, dynamic> map) {
    return Walletmodel(
      email: map['email'] != null ? map['email'] as String : null,
      bitcoin_address: map['bitcoin_address'] != null ? map['bitcoin_address'] as String : null,
      bitcoin_descriptor: map['bitcoin_descriptor'] != null ? map['bitcoin_descriptor'] as String : null,
      mnemonic: map['mnemonic'] != null ? map['mnemonic'] as String : null,
      balance_sats: map['balance_sats'] != null ? map['balance_sats'] as int : null,
      transaction_history: map['transaction_history'] != null ? List<dynamic>.from((map['transaction_history'] as List<dynamic>)) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Walletmodel.fromJson(String source) => Walletmodel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Walletmodel(email: $email, bitcoin_address: $bitcoin_address, bitcoin_descriptor: $bitcoin_descriptor, mnemonic: $mnemonic, balance_sats: $balance_sats, transaction_history: $transaction_history)';
  }

  @override
  bool operator ==(covariant Walletmodel other) {
    if (identical(this, other)) return true;
  
    return 
      other.email == email &&
      other.bitcoin_address == bitcoin_address &&
      other.bitcoin_descriptor == bitcoin_descriptor &&
      other.mnemonic == mnemonic &&
      other.balance_sats == balance_sats &&
      listEquals(other.transaction_history, transaction_history);
  }

  @override
  int get hashCode {
    return email.hashCode ^
      bitcoin_address.hashCode ^
      bitcoin_descriptor.hashCode ^
      mnemonic.hashCode ^
      balance_sats.hashCode ^
      transaction_history.hashCode;
  }
}
