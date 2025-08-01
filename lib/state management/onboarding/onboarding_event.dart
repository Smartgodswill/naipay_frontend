part of 'onboarding_bloc.dart';

@immutable
sealed class OnboardingEvent {}

class OnboardingSentOtpEvent extends OnboardingEvent {
  final String fullname;
  final String emailAddress;
  final String selectedCountry;
  final String password;
  final bool? ischecked;
  final String? referalcode;

  OnboardingSentOtpEvent({
    required this.fullname,
    required this.emailAddress,
    required this.selectedCountry,
    required this.password,
    this.referalcode,
    this.ischecked,
  });
}

class OnVerifySentOtpEvent extends OnboardingEvent {
  final String email;
  final String otp;
  final String password;

  OnVerifySentOtpEvent({
    required this.email,
    required this.otp,
    required this.password,
  });
}

class OnCreateWalletEvent extends OnboardingEvent {
  final String email;
  final String token;

  OnCreateWalletEvent({required this.email, required this.token});
}
