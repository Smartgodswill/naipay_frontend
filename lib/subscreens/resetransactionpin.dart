import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/transactionscreens/verifytransactionpinscreen.dart';
import 'package:naipay/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetransactionpinScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> userInfo;
  final String fromAddress;
  final String toAddress;
  final double amount;
  final Map<String, dynamic> previewData;
  final String coin;
  final Map<String, dynamic> walletInfo;
  const ResetransactionpinScreen({
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
  State<ResetransactionpinScreen> createState() =>
      _ResetransactionpinScreenState();
}

class _ResetransactionpinScreenState extends State<ResetransactionpinScreen> {
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _loading = false;
  bool _visible = false;
  bool _confirmvisible = false;

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: screenWidth - 40, 
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reset your transaction pin',
                style: TextStyle(color: kmainWhitecolor, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                maxLength: 6,
                keyboardType: TextInputType.number,
                controller: _newPinController,
                style: TextStyle(color: kwhitecolor),
                obscureText: !_visible,
                decoration: InputDecoration(
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _visible = !_visible;
                      });
                    },
                    child: Icon(
                      _visible ? Icons.visibility : Icons.visibility_off,
                      color: kmainWhitecolor,
                    ),
                  ),
                  labelText: 'New pin',
                  hintText: 'Enter new pin',
                  hintStyle: TextStyle(color: kmainWhitecolor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                maxLength: 6,
                keyboardType: TextInputType.number,
                controller: _confirmPinController,
                style: TextStyle(color: kwhitecolor),
                obscureText: !_confirmvisible,
                decoration: InputDecoration(
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _confirmvisible = !_confirmvisible;
                      });
                    },
                    child: Icon(
                      _confirmvisible ? Icons.visibility : Icons.visibility_off,
                      color: kmainWhitecolor,
                    ),
                  ),
                  labelText: 'Confirm new pin',
                  hintText: 'Confirm new pin',
                  hintStyle: TextStyle(color: kmainWhitecolor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 50),
               Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: GestureDetector(
                        onTap: () async {
                          final newPin = _newPinController.text.trim();
                          final confirmPin = _confirmPinController.text.trim();

                          if (newPin.isEmpty || confirmPin.isEmpty) {
                            customSnackBar(
                              "Please fill in both fields",
                              context,
                            );
                            return;
                          }

                          if (newPin != confirmPin) {
                            customSnackBar("PINs do not match", context);
                            return;
                          }

                          setState(() {
                            _loading = true;
                          });

                          try {
                            await UserService().updateTransactionPin(
                              widget.email,
                              newPin,
                            );

                            customSnackBar(
                              'Transaction pin updated successfully',
                              context,
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SetTransactionPinView(
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
                          } catch (e) {
                            customSnackBar("An error occurred: $e", context);
                          } finally {
                            setState(() {
                              _loading = false;
                            });
                          }
                        },
                        child: Container(
                          height: 45,
                          width: 250,
                          decoration: BoxDecoration(
                            color: kwhitecolor,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child:_loading
                  ? Center(child: CircularProgressIndicator(color: kmainBackgroundcolor))
                  : Text(
                            'Update',
                            style: TextStyle(
                              color: kmainWhitecolor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
