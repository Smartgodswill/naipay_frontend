import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/screens/verifyloginotp.dart';
import 'package:naipay/screens/registerscreen.dart';
import 'package:naipay/state%20management/restorewallet/bloc/restorewallet_bloc.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscureText = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kmainBackgroundcolor,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back_ios, color: kwhitecolor, size: 20),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: kmainBackgroundcolor,
      body: SingleChildScrollView(
        child: BlocConsumer<RestorewalletBloc, RestorewalletState>(
          listener: (context, state) {
            if (state is RestorewalletSuccessState) {
              customSnackBar('Otp send successfully', context);
               Navigator.push(context, MaterialPageRoute(builder: (context){
                return  VerifyloginOtpScreen();
              }));
            } else if (state is RestorewalletFailureState) {
              customDialog(context, state.message);
             
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                SizedBox(height: 35),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        'Welcome Back!',
                        style: TextStyle(color: kwhitecolor, fontSize: 30),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        ' logIn',
                        style: TextStyle(color: kwhitecolor, fontSize: 20),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: customContainer(
                    60,
                    size.width / 1.1,
                    BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: ksubbackgroundcolor,
                          blurRadius: 5,
                          spreadRadius: 0.9,
                        ),
                      ],
                      color: ksubbackgroundcolor,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: kmainBackgroundcolor),
                          hintText: 'Enter your email',
                          border: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.email_rounded,
                            color: kmainBackgroundcolor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: customContainer(
                    60,
                    size.width / 1.1,
                    BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: ksubbackgroundcolor,
                          blurRadius: 5,
                          spreadRadius: 0.9,
                        ),
                      ],
                      color: ksubbackgroundcolor,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: passwordController,
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: kmainBackgroundcolor),
                          hintText: 'Enter your password',
                          border: InputBorder.none,
                          suffixIcon: InkWell(
                            onTap: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                            child: Icon(
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: kmainBackgroundcolor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Text(
                        'Forgotten Password?',
                        style: TextStyle(color: kwhitecolor, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 80),
               InkWell(
                onTap: state is RestorewalleLoadingState?null:(){
                  context.read<RestorewalletBloc>().add(RestoreUsersWalletOtpEvent(emailController.text, passwordController.text));
                },
                 child: customContainer(50, 300, BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: ksubcolor
                 ), Center(child: state is RestorewalleLoadingState? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ksubbackgroundcolor,
                  ),
                ): Text('Login',style: TextStyle(color: kwhitecolor),),)),
               ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: kwhitecolor),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return RegisterScreen();
                            },
                          ),
                        );
                      },
                      child: Text(
                        ' Register',
                        style: TextStyle(
                          color: kwhitecolor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
