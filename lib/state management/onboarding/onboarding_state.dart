part of 'onboarding_bloc.dart';

@immutable
sealed class OnboardingState {}

final class OnboardingInitial extends OnboardingState {}

class OnboardingSentOtploadingState extends OnboardingState {
  final String message;
  OnboardingSentOtploadingState( this.message);
}

class OnboardingSentOtpSuccessState extends OnboardingState {
  final String? bitcoinAddress;
  final String? lightningAddress;
  final String? tronAddress;
  final int? balanceSats;

  OnboardingSentOtpSuccessState({
    this.bitcoinAddress,
    this.lightningAddress,
    this.tronAddress,
    this.balanceSats,
  });
}

class OnboardingOtpResendSuccessState extends OnboardingState {}

class OnboardingSentOtpFailureState extends OnboardingState {
  final String message;
  OnboardingSentOtpFailureState(this.message);
}
