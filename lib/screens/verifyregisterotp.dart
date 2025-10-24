import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/main.dart';
import 'package:naipay/model/getusersmodels.dart' show Getuser;
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/state%20management/onboarding/onboarding_bloc.dart';
import 'package:naipay/subscreens/homepage.dart';
import 'package:naipay/theme/colors.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:naipay/utils/utils.dart';

class VerifyRegisterOtpScreen extends StatefulWidget {
  final String email;
  final String fullname;
  final String selectedCountry;
  final String password;

  const VerifyRegisterOtpScreen({
    super.key,
    required this.email,
    required this.fullname,
    required this.selectedCountry,
    required this.password,
  });

  @override
  State<VerifyRegisterOtpScreen> createState() =>
      _VerifyRegisterOtpScreenState();
}

class _VerifyRegisterOtpScreenState extends State<VerifyRegisterOtpScreen> {
  final otpController = TextEditingController();
  bool canResend = true;
  int resendTimer = 5;
  Timer? _countdownTimer;
  bool isVerifying = false; // For Verify OTP button loading

  void _startCoolDown() {
    setState(() {
      canResend = false;
      resendTimer = 30;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (resendTimer == 0) {
        timer.cancel();
        setState(() {
          canResend = true;
        });
      } else {
        setState(() {
          resendTimer--;
        });
      }
    });
  }

  Future<void> _showErrorDialog(String message) async {
    // Ensure dialog shows after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dismiss dialog
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) async {
          if (state is OnboardingOtpResendSuccessState) {
            customSnackBar('OTP resend requested', context);
          } else if (state is OnboardingSentOtpSuccessState) {
            // OTP verified successfully
            setState(() => isVerifying = false);

            customSnackBar('OTP verified', context);
            await MyApp.showLocalNotification(
              "Welcome to Bitsure 🎉",
              "You’re all set. Enjoy easy and safe crypto management!",
              {"type": "welcome"},
            );
            final userInfo = await UserService().getUsersInfo(
              Getuser(email: widget.email),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    Homepage(email: widget.email, userInfo: userInfo),
              ),
            );
          } else if (state is OnboardingSentOtpFailureState) {
            setState(() => isVerifying = false);
            _showErrorDialog(state.message);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 110),
                Center(
                  child: Text(
                    "Verify OTP",
                    style: TextStyle(
                      color: kmainWhitecolor,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 320,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "An OTP code has been sent to your email ${widget.email}. Please input it here to continue.",
                        style: TextStyle(color: kmainWhitecolor, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: otpController,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    keyboardType: TextInputType.number,
                    autoFocus: true,
                    textStyle: TextStyle(color: kwhitecolor),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 55,
                      fieldWidth: 52,
                      activeFillColor: ksubbackgroundcolor,
                      inactiveFillColor: kwhitecolor,
                      selectedFillColor: kwhitecolor,
                      activeColor: kmainBackgroundcolor,
                      selectedColor: kwhitecolor,
                      inactiveColor: Colors.grey,
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                  ),
                ),
                const SizedBox(height: 3),
                customButtonContainer(
                  40,
                  size.width * 0.8,
                  BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: kwhitecolor,
                        blurStyle: BlurStyle.solid,
                        blurRadius: 5,
                        spreadRadius: 0.9,
                      ),
                    ],
                    color: kmainBackgroundcolor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  Center(
                    child: BlocBuilder<OnboardingBloc, OnboardingState>(
                      builder: (context, state) {
                        if (state is OnboardingSentOtploadingState) {
                          return Text(
                            state.message,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          );
                        }
                        return const Text(
                          'Verify OTP',
                          style: TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  () {
                    if (isVerifying) return;

                    setState(() => isVerifying = true);

                    context.read<OnboardingBloc>().add(
                      OnVerifySentOtpEvent(
                        email: widget.email,
                        otp: otpController.text,
                        password: widget.password,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 25, top: 5),
                  child: Row(
                    children: [
                      Text(
                        "Didn't get a code?",
                        style: TextStyle(color: kmainWhitecolor, fontSize: 16),
                      ),
                      InkWell(
                        onTap: canResend
                            ? () {
                                context.read<OnboardingBloc>().add(
                                  OnboardingSentOtpEvent(
                                    fullname: widget.fullname,
                                    emailAddress: widget.email,
                                    selectedCountry: widget.selectedCountry,
                                    password: widget.password,
                                  ),
                                );
                                customSnackBar("OTP resend requested", context);
                                _startCoolDown();
                              }
                            : null,
                        child: Text(
                          canResend
                              ? " Resend"
                              : " Resending OTP in $resendTimer sec",
                          style: TextStyle(color: kwhitecolor, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
