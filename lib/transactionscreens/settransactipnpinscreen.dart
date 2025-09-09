import 'package:flutter/material.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/subscreens/homepage.dart';
import 'package:naipay/transactionscreens/sendfundscreen.dart';
import 'package:naipay/utils/utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class SetTransactionPinScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> userinfo;
  final String coin;
  final double balance;
  final double usdtEquivalent;
  final Map<String, dynamic> wallets;

  const SetTransactionPinScreen({
    super.key,
    required this.email,
    required this.userinfo,
    required this.coin,
    required this.balance,
    required this.usdtEquivalent,
    required this.wallets,
  });

  @override
  State<SetTransactionPinScreen> createState() => _SetTransactionPinScreenState();
}

class _SetTransactionPinScreenState extends State<SetTransactionPinScreen> with TickerProviderStateMixin {
  final TextEditingController setPinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();
  bool isConfirmStep = false;
  bool isSubmitting = false;

  @override
  void dispose() {
    setPinController.clear();
    confirmPinController.clear();
    setPinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  void _onPinCompleted() async {
    if (isSubmitting) return; // Prevent double submission
    if (!isConfirmStep) {
      if (setPinController.text.isEmpty) {
        _showSnack("❌ PIN cannot be empty", Colors.red);
        return;
      }
      setState(() {
        isConfirmStep = true;
        confirmPinController.clear();
      });
    } else {
      if (confirmPinController.text.isEmpty) {
        _showSnack("❌ Confirm PIN cannot be empty", Colors.red);
        return;
      }
      if (setPinController.text != confirmPinController.text) {
        _showSnack("❌ PINs do not match. Try again.", Colors.red);
        setState(() {
          setPinController.clear();
          confirmPinController.clear();
          isConfirmStep = false;
        });
        return;
      }

      setState(() {
        isSubmitting = true;
      });
      await _sendPinToBackend(setPinController.text.trim(), widget.email);
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendPinToBackend(String pin, String email) async {
    try {
      FocusScope.of(context).unfocus();
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kmainWhitecolor),
              const SizedBox(height: 16),
              Text("Setting PIN...", style: TextStyle(color: kmainWhitecolor)),
            ],
          ),
        ),
      );

      // Send PIN to backend
      await UserService().sendPinToBackend(email, pin);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Update userinfo
      setState(() {
        widget.userinfo['hasTransactionPin'] = true;
      });

      _showSnack("✅ PIN set successfully!", Colors.green);

      // Navigate to Sendfundscreen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Sendfundscreen(
              userInfo: widget.userinfo,
              coin: widget.coin,
              balance: widget.balance,
              usdtEquivalent: widget.usdtEquivalent,
              wallets: widget.wallets,
            ),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      _showSnack("❌ Failed to set PIN: $e", Colors.red);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 150),
            Text(
              isConfirmStep ? 'Confirm Transaction PIN' : 'Set Transaction PIN',
              style: TextStyle(color: kmainWhitecolor, fontSize: 23),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 250,
                child: Text(
                  isConfirmStep
                      ? 'Please re-enter your initial PIN to confirm.'
                      : 'Please be aware this is your wallet transaction PIN. Do not share it.',
                  style: TextStyle(color: kmainWhitecolor, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: PinCodeTextField(
                key: ValueKey('pinField-$isConfirmStep'), // Unique key to force widget recreation
                textStyle: TextStyle(color: kwhitecolor),
                appContext: context,
                length: 6,
                controller: isConfirmStep ? confirmPinController : setPinController,
                obscureText: true,
                animationType: AnimationType.none, // Disable animations to avoid ticker issues
                keyboardType: TextInputType.number,
                autoFocus: false, // Disable autofocus to reduce focus-related issues
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
                animationDuration: const Duration(milliseconds: 0),
                enableActiveFill: true,
                onCompleted: (_) => _onPinCompleted(),
                onChanged: (_) {},
                enabled: !isSubmitting, // Disable input during submission
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 50),
                  backgroundColor: kwhitecolor,
                ),
                onPressed: isSubmitting ? null : _onPinCompleted,
                child: isSubmitting
                    ? CircularProgressIndicator(color: kmainBackgroundcolor)
                    : Text(
                        'Set Pin',
                        style: TextStyle(
                          color: kmainBackgroundcolor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}