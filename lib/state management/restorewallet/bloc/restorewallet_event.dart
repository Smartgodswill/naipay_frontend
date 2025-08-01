part of 'restorewallet_bloc.dart';

@immutable
sealed class RestorewalletEvent {}

class RestoreUsersWalletOtpEvent extends RestorewalletEvent {
  final String email;
  final String password;

  RestoreUsersWalletOtpEvent(this.email, this.password);
}

class RestoreUsersWalletVerifyOtpEvent extends RestorewalletEvent {
  final String email;
  final String otp;

  RestoreUsersWalletVerifyOtpEvent(this.email, this.otp);
}
