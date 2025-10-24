import 'package:flutter/material.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/subscreens/resetransactionpin.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ResetPinOtpScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> userInfo;
  final String fromAddress;
  final String toAddress;
  final double amount;
  final Map<String, dynamic> previewData;
  final String coin;
  final Map<String, dynamic> walletInfo;
  const ResetPinOtpScreen({
    super.key,
    required this.email,
    required this.userInfo,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.previewData,
    required this.coin,
    required this.walletInfo,
  });

  @override
  State<ResetPinOtpScreen> createState() => _ResetPinOtpScreenState();
}

class _ResetPinOtpScreenState extends State<ResetPinOtpScreen> {
  String otpValue = "";

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 90),
            Center(
              child: Text(
                'Verify OTP',
                style: TextStyle(
                  color: kmainWhitecolor,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "We’ve sent a one-time PIN to your email ${widget.email}. Please enter it below to verify your identity and continue with your reset",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: PinCodeTextField(
                appContext: context,
                length: 6,
                textStyle: TextStyle(
                  color: kwhitecolor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                obscureText: false,
                keyboardType: TextInputType.number,
                autoFocus: true,
                animationType: AnimationType.fade,
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
                onChanged: (value) {
                  otpValue = value;
                },
                onCompleted: (value) {
                  otpValue = value;
                },
              ),
            ),
            customButtonContainer(
              50,
              size.width * 0.7,
              BoxDecoration(
                color: kmainBackgroundcolor,
                boxShadow: [
                  BoxShadow(
                    color: kwhitecolor,
                    blurRadius: 0.5,
                    spreadRadius: 0.8,
                    blurStyle: BlurStyle.solid,
                  ),
                ],
                borderRadius: BorderRadius.circular(25),
              ),
              Center(
                child: Text('Verify', style: TextStyle(color: kwhitecolor)),
              ),
              () async {
                try {
                  if (otpValue.isEmpty || otpValue.length < 6) {
                    customSnackBar('OTP fields cannot be empty', context);
                    return;
                  }
                  final verified = await UserService()
                      .verifyResetTransactionPinOTP(widget.email, otpValue);
                  if (verified) {
                    customSnackBar('OTP verified successfully', context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResetransactionpinScreen(
                          email: widget.email,
                          userInfo: widget.userInfo,
                          fromAddress: widget.fromAddress,
                          toAddress: widget.toAddress,
                          amount: widget.amount,
                          previewData: widget.previewData,
                          coin: widget.coin,
                          walletInfo: widget.walletInfo,
                        ),
                      ),
                    );
                  } else {
                    customSnackBar('Invalid OTP', context);
                  }
                } catch (e) {
                  customSnackBar('Failed to verify OTP', context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
