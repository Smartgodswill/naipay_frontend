// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Getuser {
  String? email;
  String? fullname;
  String? referal_count;
  String? referal_code;
  Getuser({
    this.email,
    this.fullname,
    this.referal_count,
    this.referal_code,
  });

  Getuser copyWith({
    String? email,
    String? fullname,
    String? referal_count,
    String? referal_code,
  }) {
    return Getuser(
      email: email ?? this.email,
      fullname: fullname ?? this.fullname,
      referal_count: referal_count ?? this.referal_count,
      referal_code: referal_code ?? this.referal_code,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'fullname': fullname,
      'referal_count': referal_count,
      'referal_code': referal_code,
    };
  }

  factory Getuser.fromMap(Map<String, dynamic> map) {
    return Getuser(
      email: map['email'] != null ? map['email'] as String : null,
      fullname: map['fullname'] != null ? map['fullname'] as String : null,
      referal_count: map['referal_count'] != null ? map['referal_count'] as String : null,
      referal_code: map['referal_code'] != null ? map['referal_code'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Getuser.fromJson(String source) => Getuser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Getuser(email: $email, fullname: $fullname, referal_count: $referal_count, referal_code: $referal_code)';
  }

  @override
  bool operator ==(covariant Getuser other) {
    if (identical(this, other)) return true;
  
    return 
      other.email == email &&
      other.fullname == fullname &&
      other.referal_count == referal_count &&
      other.referal_code == referal_code;
  }

  @override
  int get hashCode {
    return email.hashCode ^
      fullname.hashCode ^
      referal_count.hashCode ^
      referal_code.hashCode;
  }
}
