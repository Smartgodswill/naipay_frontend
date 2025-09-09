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
  final String toAddress;
  final double amount;
  final Map<String, dynamic> previewData;
  final String coin;

  const SetTransactionPinView({
    required this.userInfo,
    required this.fromAddress,
    required this.toAddress,
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
      appBar: AppBar(
        backgroundColor: ktransparentcolor,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: kmainBackgroundcolor,
      body: BlocConsumer<SendtransactionpinBloc, SendtransactionpinState>(
        listener: (context, state) {
          if (state is TransactionFailure) {
            _hideLoading();
            customSnackBar(state.error, context);
          } else if (state is PinVerified) {
            _hideLoading();
            customSnackBar("✅ PIN verified, proceeding...", context);
            final int amountInSats = (widget.coin.toUpperCase() == 'BTC')
                  ? (widget.amount * 100000000).toInt() // Convert BTC to satoshis
                  : widget.amount.toInt();
             try {
               context.read<SendtransactionpinBloc>().add(
                    SendBTCTransactionEvent(
                      email: widget.userInfo['email'],
                      previewData: widget.previewData,
                      fromAddress: widget.fromAddress,
                      toAddress: widget.toAddress,
                      amount: amountInSats,
                      coin: widget.coin,
                      walletInfo: widget.walletInfo,
                    ),
                  );
             } catch (e) {
              print('Error adding SendBTCTransactionEvent: $e');
             }
          }
        },
        builder: (context, state) {
          if (state is PinLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showLoading("Processing...");
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _hideLoading();
            });
          }

          if (state is TransactionSuccess) {
            final tx = state.transactionData;
            print('TransactionSuccess txData in SetTransactionPinView: $tx'); // Debug log
            final updatedWalletInfo = tx['updatedWalletInfo'] ?? widget.walletInfo;
            final lastSentAddress = widget.toAddress;
            final double amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
            final double fee = double.tryParse(tx['fee'].toString()) ?? 0.0;
            final double total = amount + fee;

            if (widget.coin.toUpperCase() == 'USDT') {
              final List<Map<String, dynamic>> trc20Transactions =
                  List<Map<String, dynamic>>.from(
                      updatedWalletInfo['trc20Transactions'] ?? []);

              return _TransactionSummary(
                txData: tx,
                onBack: () {
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Homepage(
                        email: widget.userInfo['email'],
                        address: lastSentAddress,
                        pendingOutgoingBtc: 0,
                        pendingOutgoingUsdt: total,
                        userInfo: {
                          ...widget.userInfo,
                          'usdt_balance': updatedWalletInfo['usdt_balance'],
                        },
                        trc20Transactions: trc20Transactions,
                      ),
                    ),
                    (route) => false,
                  );
                },
              );
            } else {
              return _TransactionSummary(
                txData: tx,
                onBack: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Homepage(
                        email: widget.userInfo['email'],
                        address: lastSentAddress,
                        pendingOutgoingBtc: total,
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
          }

          return _PinInput(
            onPinCompleted: (pin) {
              final int amountInSats = (widget.coin.toUpperCase() == 'BTC')
                  ? (widget.amount * 100000000).toInt() 
                  : widget.amount.toInt();
              context.read<SendtransactionpinBloc>().add(
                    VerifyPinEvent(
                      widget.userInfo['email'],
                      pin,
                      sendTransactionEvent: SendBTCTransactionEvent(
                        email: widget.userInfo['email'],
                        previewData: widget.previewData,
                        fromAddress: widget.fromAddress,
                        toAddress: widget.toAddress,
                        amount: amountInSats,
                        coin: widget.coin,
                        walletInfo: widget.walletInfo,
                      ),
                    ),
                  );
            },
            controller: pinController,
          );
        },
      ),
    );
  }
}

class _PinInput extends StatelessWidget {
  final void Function(String) onPinCompleted;
  final TextEditingController controller;

  const _PinInput({
    required this.onPinCompleted,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Transaction PIN',
          style: TextStyle(color: kmainWhitecolor, fontSize: 23),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: 302,
            child: Text(
              'Please input the pin you set initially when you registered to confirm it you',
              style: TextStyle(color: kmainWhitecolor, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: PinCodeTextField(
            textStyle: TextStyle(color: kwhitecolor),
            appContext: context,
            length: 6,
            controller: controller,
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
            onCompleted: onPinCompleted,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 8),
              child: Text('Forgotten Pin? ', style: TextStyle(color: kmainWhitecolor)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 8),
              child: Text('Reset Pin', style: TextStyle(color: kwhitecolor)),
            )
          ],
        )
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
    print('Rendering _TransactionSummary with txData: $txData'); // Debug log
    final double amount = double.tryParse(txData['amount'].toString()) ?? 0.0;
    final double fee = double.tryParse(txData['fee'].toString()) ?? 0.0;
    final double total = amount + fee;
    final String coin = txData['coin']?.toString().toUpperCase() ?? 'USDT';

    String formatCryptoAmount(double value, String coin) {
      if (coin == 'USDT') {
        String formatted = value.toStringAsFixed(6).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
        return formatted.endsWith('.000000') ? formatted.replaceAll('.000000', '') : '$formatted USDT';
      } else if (coin == 'BTC') {
        return '${value.toStringAsFixed(8).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} BTC';
      }
      return value.toString();
    }

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
                    Text(
                      'From: ${txData['fromAddress'] ?? 'N/A'}',
                      style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'To: ${txData['toAddress'] ?? 'N/A'}',
                      style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Amount: ${formatCryptoAmount(amount, coin)}',
                          style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Fee: ${formatCryptoAmount(fee, coin)}',
                          style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      'TxID: ${txData['txid'] ?? 'N/A'}',
                      style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Total amount sent: ${formatCryptoAmount(total, coin)}',
                          style: TextStyle(
                            color: kmainWhitecolor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Back to Homepage', style: TextStyle(color: kmainWhitecolor)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Implement share receipt logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ksubcolor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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