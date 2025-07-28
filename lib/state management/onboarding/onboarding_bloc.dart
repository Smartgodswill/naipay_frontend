import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:naipay/model/user.dart';
import 'package:naipay/model/walletmodel.dart';
import 'package:naipay/services/user_service.dart';
import 'package:naipay/services/walletservice.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingInitial()) {
    on<OnboardingSentOtpEvent>(_onRegisterUser);
    on<OnVerifySentOtpEvent>(_onVerifyUser);
  }

  Future<void> _onRegisterUser(
    OnboardingSentOtpEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingSentOtploadingState());
    try {
      final user = User(
        fullname: event.fullname,
        email: event.emailAddress,
        country: event.selectedCountry,
        referred_by: event.referalcode,
        password: event.password,
      );

      await UserService().signup(user);
      emit(OnboardingSentOtpSuccessState());
    } catch (e) {
      emit(
        OnboardingSentOtpFailureState(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onVerifyUser(
    OnVerifySentOtpEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingSentOtploadingState());
    if (event.otp.isEmpty) {
      emit(OnboardingSentOtpFailureState('Otp fields cannot be empty'));
      return;
    }
    try {
      final user = User(email: event.email.trim(), otp: event.otp.trim());
      print("Verifying OTP for user: ${user.email}");
      print("User OTP: ${user.otp}"); 

        await UserService().verifyOtp(user);
      print("OTP verified");
      final walletData = await WalletService().createBitcoinAndTronWallet(
        event.email.trim(),
      );
      print('Wallet data: $walletData');

      final createWalletUser =  Walletmodel(
        email: event.email,
        bitcoin_address: walletData['bitcoin_address'],
        bitcoin_descriptor: walletData['bitcoin_descriptor'],
        mnemonic: walletData['mnemonic'],
        balance_sats: int.parse(walletData['balance_sats'] .toString()), 
        transaction_history: walletData['transaction_history'],
       
      );

      print("Created wallet user: ${createWalletUser.email}");
      print(
        "Sending wallet user to backend: ${jsonEncode(createWalletUser.toJson())}",
      );

      await UserService().createWalletAndSendToBackend(createWalletUser);
      print("Wallet sent to backend");
      emit(OnboardingSentOtpSuccessState());
    } catch (e, stackTrace) {
      print('Verify user error: $e');
      print('Verify user stack trace: $stackTrace');
      emit(
        OnboardingSentOtpFailureState(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
