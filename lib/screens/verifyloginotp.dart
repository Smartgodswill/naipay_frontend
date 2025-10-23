import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/main.dart';
import 'package:naipay/state%20management/restorewallet/bloc/restorewallet_bloc.dart';
import 'package:naipay/subscreens/homepage.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyloginOtpScreen extends StatefulWidget {
  final String email;
  final String password;
  const VerifyloginOtpScreen({super.key, required this.email, required this.password});

  @override
  State<VerifyloginOtpScreen> createState() => _VerifyloginOtpScreenState();
}

class _VerifyloginOtpScreenState extends State<VerifyloginOtpScreen> {
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
    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: SingleChildScrollView(
        child: BlocConsumer<RestorewalletBloc, RestorewalletState>(
          listener: (context, state) async {
            if (state is RestoreVerifiedwalletSuccessState){
              print(
                'On HomePage NAviGated DATA:${state.mnemonic},${state.userInfo},${widget.email}',
              );
                  await MyApp.showLocalNotification(
    "Welcome back to Bitsure 🎉",
    "You’re all set  enjoy easy and safe crypto management!",
    {"type": "welcome"},
  );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                 
                    return Homepage(
                      wallets: state.mnemonic,
                      userInfo: state.userInfo,
                      email: widget.email,
                    );
                  },
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                SizedBox(height: 90),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Verify OTP',
                      style: TextStyle(
                        color: kmainWhitecolor,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 330,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "An OTP to login into your account has been send to your email please input them here to confirm it's actually you.",
                          style: TextStyle(
                            color: kmainWhitecolor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: PinCodeTextField(
                    textStyle: TextStyle(color: kwhitecolor),
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
               customButtonContainer(
  40,
  300,
  BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: kmainBackgroundcolor,
    boxShadow: [
      BoxShadow(
        color: kwhitecolor,
        blurRadius: 0.5,
        spreadRadius: 0.8,
        blurStyle: BlurStyle.solid,
      ),
    ],
  ),
  Center(
    child: state is RestorewalleLoadingState
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.message,
                style:  TextStyle(color: kmainWhitecolor),
              ),
              const SizedBox(width: 8),
             SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kmainWhitecolor),
                ),
              ),
            ],
          )
        :  Text(
            'Verify',
            style: TextStyle(color: kmainWhitecolor),
          ),
  ),
  (state is RestorewalleLoadingState)
      ? null
      : () {
          if (state is! RestorewalleLoadingState) {
            context.read<RestorewalletBloc>().add(
                  RestoreUsersWalletVerifyOtpEvent(
                    widget.email,
                    otpController.text.trim(),
                  ),
                );
          }
        },
),

                Padding(
                  padding: const EdgeInsets.only(left: 25, top: 40),
                  child: Row(
                    children: [
                      Text(
                        "Did'nt get a code?",
                        style: TextStyle(color: kmainWhitecolor, fontSize: 15),
                      ),
                           InkWell(
                        onTap: canResend
                            ? () {
                                context.read<RestorewalletBloc>().add(
                               RestoreUsersWalletOtpEvent(widget.email, widget.password)
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
            );
          },
        ),
      ),
    );
  }
}
