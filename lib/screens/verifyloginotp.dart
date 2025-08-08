import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/state%20management/restorewallet/bloc/restorewallet_bloc.dart';
import 'package:naipay/subscreens/homepage.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyloginOtpScreen extends StatefulWidget {
  final String email;
  const VerifyloginOtpScreen({super.key, required this.email,});

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
        child: BlocConsumer<RestorewalletBloc, RestorewalletState>(
          listener: (context, state) {
           if(state is RestoreVerifiedwalletSuccessState){
             print('On HomePage NAviGated DATA:${state.mnemonic},${state.userInfo},${widget.email}');
            Navigator.push(context, MaterialPageRoute(builder: (context){
              return  Homepage(wallets: state.mnemonic,userInfo:  state .userInfo,email: widget.email,);
            }));
           
           }else if (state is RestorewalleLoadingState) {
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
                                  Text('verifying OTP\nplease wait...',
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
                          'An OTP to login into your account has been send to your email please input them here to confirm it actually you. ',
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
                    onCompleted: (value) {
                      context.read<RestorewalletBloc>().add(RestoreUsersWalletVerifyOtpEvent(widget.email,otpController.text));
                    },
                  ),
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
                        onTap: () {},

                        child: Text(
                          ' Resend',
                          style: TextStyle(
                            color: kwhitecolor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
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
