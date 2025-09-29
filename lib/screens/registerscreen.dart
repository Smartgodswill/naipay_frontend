import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:naipay/screens/loginscreen.dart';
import 'package:naipay/screens/verifyregisterotp.dart';
import 'package:naipay/state%20management/onboarding/onboarding_bloc.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';
import 'package:country_picker/country_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();
  final _referralController = TextEditingController();
  final _passwordController = TextEditingController();
  String? selectedCountry;
  String? referralError;
  bool obscureText = true;
  bool isBoxChecked = false;

  // Prevents double-tap
  bool isSubmitting = false;
  bool hasNavigated = false; // Add this in _RegisterScreenState

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        // Reset submit flag on any response
        setState(() => isSubmitting = true);

        if (state is OnboardingSentOtpSuccessState) {
          customSnackBar('Otp sent successfully', context);
          hasNavigated = true; 
            final secureStorage = const FlutterSecureStorage(); 
                var storedEmail=    secureStorage.write(key: 'user_email', value: _emailController.text.trim());
                print(" ✅ email stored on user devices is  $storedEmail");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyRegisterOtpScreen(
                email: _emailController.text.trim(),
                fullname: _firstNameController.text,
                password: _passwordController.text,
                selectedCountry: _countryController.text,
              ),
            ),
          );
            setState(() => hasNavigated = false);
        
        }

        if (state is OnboardingSentOtpFailureState) {
          customDialog(context, state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: kmainBackgroundcolor,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  _buildTitle(),
                  _buildDescription(),
                  const SizedBox(height: 32),

                  _buildTextField(
                    _firstNameController,
                    false,
                    Icons.person,
                    "Enter fullname",
                  ),
                  const SizedBox(height: 15),

                  _buildTextField(
                    _emailController,
                    false,
                    Icons.email,
                    "Enter email address",
                  ),
                  const SizedBox(height: 15),

                  _buildCountryPicker(),
                  const SizedBox(height: 15),

                  _buildTextField(
                    _passwordController,
                    obscureText,
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    "Enter password",
                    ontap: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    _referralController,
                    false,
                    Icons.radar,
                    "Enter referral code (optional)",
                    onChanged: (_) => setState(() => referralError = null),
                  ),
                  if (referralError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 5, top: 5),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          referralError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 500,
                    child: Row(
                      children: [
                        Checkbox(
                          value: isBoxChecked,
                          onChanged: (value) {
                            setState(() {
                              isBoxChecked = value!;
                            });
                          },
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'By creating this account you have accepted\n',
                                style: TextStyle(color: kmainWhitecolor),
                              ),
                              TextSpan(
                                text: 'the terms ',
                                style: TextStyle(
                                  color: kwhitecolor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: 'and ',
                                style: TextStyle(
                                  color: kmainWhitecolor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: 'conditions',
                                style: TextStyle(color: kwhitecolor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Submit Button
                  customButtonContainer(
                    size.height / 18,
                    size.width * 0.7,
                    BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurStyle: BlurStyle.solid,
                          color: kwhitecolor,
                          blurRadius: 0.9,
                          spreadRadius: 2,
                        ),
                      ],
                      color: kmainBackgroundcolor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    Center(
                      child: state is OnboardingSentOtploadingState || isSubmitting
                          ? CircularProgressIndicator(color: kmainBackgroundcolor)
                          : Text(
                              'Create Account',
                              style: TextStyle(
                                color: kmainWhitecolor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    () async {
                      if (!isSubmitting && isBoxChecked) {
                        setState(() => isSubmitting = true);
                        await _onNextPressed(context);
                      }
                    },
                  ),

                  const SizedBox(height: 15),

                  // Already have account?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: kmainWhitecolor),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return LoginScreen();
                          }));
                        },
                        child: Text(
                          ' Sign In',
                          style: TextStyle(
                            color: kwhitecolor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() => Padding(
        padding: const EdgeInsets.only(left: 15, top: 8),
        child: Row(
          children: [
            Text(
              'Create an Account',
              style: TextStyle(color: kmainWhitecolor, fontSize: 25),
            ),
          ],
        ),
      );

  Widget _buildDescription() => Padding(
        padding: const EdgeInsets.only(left: 15, right: 10),
        child: Text(
          'Ensure you provide your legal name as it appears on your government issued credentials',
          style: TextStyle(color: kmainWhitecolor, fontSize: 13),
        ),
      );

  Widget _buildTextField(
    TextEditingController controller,
    bool obscureText,
    IconData? icon,
    String hint, {
    void Function(String)? onChanged,
    GestureTapCallback? ontap,
  }) =>
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: customContainer(
          50,
          MediaQuery.of(context).size.width * 0.9,
          BoxDecoration(
            boxShadow: [
              BoxShadow(color: kwhitecolor, blurRadius: 0.9, spreadRadius: 2,blurStyle: BlurStyle.solid),
            ],
            borderRadius: BorderRadius.circular(13),
            color: kmainBackgroundcolor,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 5, top: 2),
            child: TextFormField(
               style: TextStyle(color: Colors.white),
              obscureText: obscureText,
              controller: controller,
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: InkWell(
                      onTap: ontap, child: Icon(icon, color: kmainBackgroundcolor)),
                ),
                hintText: hint,
                hintStyle: TextStyle(
                  color: kmainWhitecolor,
                  letterSpacing: 0.2,
                ),
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      );

  Widget _buildCountryPicker() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: customContainer(
          55,
          MediaQuery.of(context).size.width * 0.9,
          BoxDecoration(
            boxShadow: [
              BoxShadow(color: kwhitecolor, blurRadius: 0.9, spreadRadius: 2,blurStyle: BlurStyle.solid),
            ],
            borderRadius: BorderRadius.circular(13),
            color: kmainBackgroundcolor,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 5),
            child: TextFormField(
               style: TextStyle(color: Colors.white),
              controller: _countryController,
              readOnly: true,
              onTap: () {
                showCountryPicker(
                  
                  context: context,
                  showPhoneCode: false,
                  countryListTheme: CountryListThemeData(
                    bottomSheetWidth: 350,
                    searchTextStyle: TextStyle(color: kmainWhitecolor),
                    textStyle: TextStyle(
                      color: kmainWhitecolor
                      
                    ),
                    bottomSheetHeight: 500,
                    backgroundColor: kmainBackgroundcolor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                  ),
                  onSelect: (Country country) {
                    setState(() {
                      selectedCountry = country.name;
                      _countryController.text = country.name;
                    });
                  },
                );
              },
              decoration: InputDecoration(
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: kwhitecolor,
                  
                ),
                hintText: 'Tap to select country',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  
                  color: kmainWhitecolor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _onNextPressed(BuildContext context) async {
    context.read<OnboardingBloc>().add(
          OnboardingSentOtpEvent(
            fullname: _firstNameController.text,
            emailAddress: _emailController.text.trim(),
            selectedCountry: selectedCountry ?? "",
            password: _passwordController.text.trim(),
            referalcode: _referralController.text.isEmpty
                ? null
                : _referralController.text.trim(),
          ),
        );
  }
}
