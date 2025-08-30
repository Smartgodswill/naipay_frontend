import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:naipay/model/registerusermodels.dart';
import 'package:naipay/model/walletmodel.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/services/walletservice.dart';
import 'package:bdk_flutter/bdk_flutter.dart';
part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingInitial()) {
    on<OnboardingSentOtpEvent>(_onRegisterUser);
    on<OnVerifySentOtpEvent>(_onVerifyUser);
  }

  String? validatePassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{10,}$',
    );

    if (!regex.hasMatch(password)) {
      return 'Password must be at least 10 characters long and include:\n• 1 uppercase letter\n• 1 lowercase letter\n• 1 number\n• 1 special character';
    }

    return null;
  }

  Future<void> _onRegisterUser(
    OnboardingSentOtpEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingSentOtploadingState());
    final passwordError = validatePassword(event.password);
    if (event.fullname.isEmpty ||
        event.emailAddress.isEmpty ||
        event.selectedCountry.isEmpty ||
        event.password.isEmpty) {
      emit(OnboardingSentOtpFailureState("Fields can not be empty"));
      return;
    }

    if (passwordError != null) {
      emit(OnboardingSentOtpFailureState(passwordError));
      return;
    }
     if (event.ischecked == false) {
      emit(OnboardingSentOtpFailureState('you must accept the terms and conditions to continue'));
      return;
    }

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
      final user = User(email: event.email.trim(), otp: event.otp.trim(),password: event.password.trim());
      print("Verifying OTP for user: ${user.email}");
      print("User OTP: ${user.otp}");

      await UserService().verifyRegisterOtp(user);
      print("OTP verified");
      final walletData = await WalletService().createBitcoinWallet(
        event.email.trim(),
        Network.Testnet
        
      );
      print('Wallet data hhh: $walletData');

      final createWalletUser = Walletmodel(
        email: event.email,
        bitcoin_address: walletData['bitcoin_address'],
        bitcoin_descriptor: walletData['bitcoin_descriptor'],
        mnemonic: walletData['mnemonic'],
        balance_sats: int.parse(walletData['balance_sats'].toString()),
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
