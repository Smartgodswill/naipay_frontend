import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/animations/animatedicon.dart';
import 'package:naipay/state%20management/sendtransactionpin/bloc/sendtransactionpin_bloc.dart';
import 'package:naipay/subscreens/homepage.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class SetTransactionPinView extends StatefulWidget {
  final Map<String, dynamic> userInfo;
    final Map<String, dynamic> walletInfo;

  final String fromAddress;
  final String toaddress;
  final int amount;
  final Map<String, dynamic> previewData;
  final String coin;

  const SetTransactionPinView({
    required this.userInfo,
    required this.fromAddress,
    required this.toaddress,
    required this.amount,
    required this.previewData,
    required this.coin,
    required this.walletInfo,
    super.key, 
  });

  @override
  State<SetTransactionPinView> createState() => _SetTransactionPinViewState();
}

class _SetTransactionPinViewState extends State<SetTransactionPinView> {
  final TextEditingController pinController = TextEditingController();
  bool _isDialogShowing = false;

  void _showLoading(String message) {
    if (!_isDialogShowing) {
      _isDialogShowing = true;
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
              Text(message, style: TextStyle(color: kmainWhitecolor)),
            ],
          ),
        ),
      );
    }
  }

  void _hideLoading() {
    if (_isDialogShowing) {
      _isDialogShowing = false;
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: ktransparentcolor,automaticallyImplyLeading: false,),
      backgroundColor: kmainBackgroundcolor,
      body: BlocConsumer<SendtransactionpinBloc, SendtransactionpinState>(
        listener: (context, state) {
          if (state is TransactionFailure) {
            _hideLoading();
            customSnackBar(state.error, context);
          } else if (state is PinSetSuccessfully) {
            _hideLoading();
            customSnackBar("✅ PIN set successfully!", context);
          } else if (state is PinVerified) {
            _hideLoading();
            customSnackBar("✅ PIN verified, proceeding...", context);
            context.read<SendtransactionpinBloc>().add(SendTransactionEvent(
                  previewData: widget.previewData,
                  fromAddress: widget.fromAddress,
                  toAddress: widget.toaddress,
                  amount: widget.amount,
                  coin: widget.coin,
                  walletInfo: widget.walletInfo,
                ));
          } else if (state is TransactionSuccess) {
            _hideLoading();
            customSnackBar("✅ Transaction sent!", context);
          }
        },
        builder: (context, state) {
          if (state is PinLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showLoading("Verifying PIN...");
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _hideLoading();
            });
          }

          if (state is TransactionSuccess) {
            final tx = state.transactionData;
       final updatedWalletInfo = tx['updatedWalletInfo'] ?? widget.walletInfo;

            return _TransactionSummary(
              txData: tx,
              onBack: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Homepage(
                      email: widget.userInfo['email'],
                      userInfo: {
                        ...widget.userInfo,
                        'bitcoin_balance': updatedWalletInfo['balance_sats'] ?? 0,
                        'transaction_history': updatedWalletInfo['transaction_history'] ?? [],
                      },
                      trc20Transactions: null,
                    ),
                  ),
                  (route) => false,
                );
              },
            );
          }

          return _PinInput(
            hasTransactionPin: widget.userInfo['hasTransactionPin'],
            onPinCompleted: (pin) {
              if (widget.userInfo['hasTransactionPin'] == true) {
                context.read<SendtransactionpinBloc>().add(
                      VerifyPinEvent(widget.userInfo['email'], pin),
                    );
              } else {
                context.read<SendtransactionpinBloc>().add(
                      SetNewPinEvent(widget.userInfo['email'], pin),
                    );
              }
            },
            controller: pinController,
          );
        },
      ),
    );
  }
}

class _PinInput extends StatelessWidget {
  final bool hasTransactionPin;
  final void Function(String) onPinCompleted;
  final TextEditingController controller;

  const _PinInput({
    required this.hasTransactionPin,
    required this.onPinCompleted,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          hasTransactionPin ? 'Enter Transaction PIN' : 'Set Transaction PIN',
          style: TextStyle(color: kmainWhitecolor, fontSize: 23),
        ),
        const SizedBox(height: 15, width: 250),
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: PinCodeTextField(
            appContext: context,
            length: 6,
            controller: controller,
            obscureText: true,
            animationType: AnimationType.fade,
            keyboardType: TextInputType.number,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(10),
              fieldHeight: 50,
              fieldWidth: 40,
              activeFillColor: Colors.white,
              inactiveFillColor: Colors.grey.shade200,
              selectedFillColor: Colors.lightBlue.shade50,
              activeColor: Colors.blue,
              selectedColor: Colors.deepPurple,
              inactiveColor: Colors.grey,
            ),
            enableActiveFill: true,
            onCompleted: onPinCompleted,
          ),
        ),
      ],
    );
  }
}

class _TransactionSummary extends StatelessWidget {
  final Map<String, dynamic> txData;
  final VoidCallback onBack;

  const _TransactionSummary({required this.txData, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final double amount = double.tryParse(txData['amount'].toString()) ?? 0.0;
    final double fee = double.tryParse(txData['fee'].toString()) ?? 0.0;
    final double total = amount + fee;

    return Column(
      children: [
        AnimatedVerifyIconPopup(),
        SizedBox(
          height: 450,
          child: Padding(
            padding: const EdgeInsets.all(9.0),
            child: Card(
              color: kmainBackgroundcolor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: kwhitecolor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Transaction Sent Successfully',
                      style: TextStyle(
                        color: kmainWhitecolor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('From: ${txData['fromAddress']}', style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold)),
                    Text('To: ${txData['toAddress']}', style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [Text('Amount: ${txData['amount']} ${txData['coin']}', style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold))],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [Text('Fee: ${txData['fee']} ${txData['coin']}', style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold))],
                    ),
                    Text('TxID: ${txData['txid']}', style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Total amount sent: ${total.toStringAsFixed(8)} ${txData['coin']}', style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: onBack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kwhitecolor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Back to Homepage', style: TextStyle(color: kmainWhitecolor)),
                        ),
                        ElevatedButton(
                          onPressed: onBack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ksubcolor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Share Receipt', style: TextStyle(color: kwhitecolor)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
