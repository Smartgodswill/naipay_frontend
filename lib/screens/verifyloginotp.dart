import 'package:flutter/material.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyloginOtpScreen extends StatefulWidget {
  const VerifyloginOtpScreen({super.key});

  @override
  State<VerifyloginOtpScreen> createState() => _VerifyloginOtpScreenState();
}

class _VerifyloginOtpScreenState extends State<VerifyloginOtpScreen> {
  final otpController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 110),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Verify OTP',style: TextStyle(color: kwhitecolor,fontSize: 30,fontWeight: FontWeight.w600),),
              ],
            ),
            SizedBox(height: 30,),
            customContainer(200, 300,BoxDecoration(
              image: DecorationImage(image: AssetImage('asset/otp.png'))
            ),SizedBox()),
            SizedBox(height: 20,),
             Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 330,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('An OTP to login into your account has been send to your email please input them here to continue ',style: TextStyle(color: kwhitecolor,fontSize: 15,fontWeight: FontWeight.w600),),
                  )),
              ],
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
                      activeFillColor: ksubbackgroundcolor,
                      inactiveFillColor: ksubbackgroundcolor,
                      selectedFillColor: Colors.lightBlue.shade50,
                      activeColor: kmainBackgroundcolor,
                      selectedColor: Colors.deepPurple,
                      inactiveColor: Colors.grey,
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    onCompleted: (value) {
                    
                    },
                  ),
                ),
                 Padding(
                  padding: const EdgeInsets.only(left: 25, top: 5),
                  child: Row(
                    children: [
                      Text(
                        "Did'nt get a code?",
                        style: TextStyle(color: kwhitecolor, fontSize: 15),
                      ),
                      InkWell(
                        onTap: (){
                              },
                            
                        child: Text(
                         ' Resend',style: TextStyle(color: kwhitecolor,fontWeight: FontWeight.w600,fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}