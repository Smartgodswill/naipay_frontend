import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/state%20management/onboarding/onboarding_bloc.dart';
import 'package:naipay/subscreens/homepage.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/transactionscreens/settransactipnpinscreen.dart';
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
  State<VerifyRegisterOtpScreen> createState() => _VerifyRegisterOtpScreenState();
}

class _VerifyRegisterOtpScreenState extends State<VerifyRegisterOtpScreen> {
  final otpController = TextEditingController();
  bool canResend = true;
  int resendTimer = 5;
  Timer? _countdownTimer;

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingOtpResendSuccessState) {
            customSnackBar('OTP resend requested', context);
          } else if (state is OnboardingSentOtpSuccessState) {
            customSnackBar('OTP verified', context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return Homepage(email: widget.email);
                },
              ),
            );
          } else if (state is OnboardingSentOtpFailureState) {
            customDialog(context, state.message);
          } else if (state is OnboardingSentOtploadingState) {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      customContainer(
                        250,
                        250,
                        BoxDecoration(borderRadius: BorderRadius.circular(20)),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  customContainer(50, 50, 
                                  BoxDecoration(
                                    color: ksubcolor,
                                    borderRadius: BorderRadius.circular(29)
                                  ), CircularProgressIndicator()),
                                  Text('Creating wallet\n please wait...',
                                  style: TextStyle(
                                    color: kwhitecolor,
                                    fontSize: 25
                                  ),),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },

        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 110),
                Center(
                  child: Text(
                    "Verify OTP",
                    style: TextStyle(color: kwhitecolor, fontSize: 30),
                  ),
                ),
                SizedBox(height: 20),
                customContainer(
                  250,
                  size.width * 0.5,
                  BoxDecoration(
                    image: DecorationImage(image: AssetImage("asset/otp.png")),
                  ),
                  SizedBox(),
                ),
                SizedBox(
                  width: 400,
                  child: Center(
                    child: Text(
                      "An OTP code has been sent to your email,\nPlease input them here to continue",
                      style: TextStyle(color: kwhitecolor, fontSize: 18),
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
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 55,
                      fieldWidth: 52,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.grey.shade200,
                      selectedFillColor: Colors.lightBlue.shade50,
                      activeColor: Colors.blue,
                      selectedColor: Colors.deepPurple,
                      inactiveColor: Colors.grey,
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    onCompleted: (value) {
                      context.read<OnboardingBloc>().add(
                        OnVerifySentOtpEvent(email: widget.email, otp: value,password: widget.password),
                      );
                      print("${widget.email} and ${widget.password}");
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25, top: 5),
                  child: Row(
                    children: [
                      Text(
                        "Did'nt get a code?",
                        style: TextStyle(color: kwhitecolor, fontSize: 16),
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
                              : " Resending otp \n in $resendTimer sec",
                          style: TextStyle(color: kwhitecolor, fontSize: 18),
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
