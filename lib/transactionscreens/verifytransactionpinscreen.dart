import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:naipay/animations/animatedicon.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/state%20management/fetchdata/bloc/fetchdata_bloc.dart';
import 'package:naipay/state%20management/sendtransactionpin/bloc/sendtransactionpin_bloc.dart';
import 'package:naipay/subscreens/homepage.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/transactionscreens/resetpinotpscreen.dart';
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
            customSnackBar("PIN verified, proceeding...", context);
            final int amountInSats = (widget.coin.toUpperCase() == 'BTC')
                ? (widget.amount * 100000000)
                      .toInt() // Convert BTC to satoshis
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
            print('TransactionSuccess txData in SetTransactionPinView: $tx');
            final updatedWalletInfo =
                tx['updatedWalletInfo'] ??
                (widget.coin.toUpperCase() == 'BTC'
                    ? widget.walletInfo
                    : widget.userInfo);
            final lastSentAddress = widget.toAddress;
            final String coin = tx['coin']?.toString().toUpperCase() ?? 'USDT';

            final double rawAmount =
                double.tryParse(tx['amount'].toString()) ?? 0.0;
            final double amount = coin == 'BTC'
                ? rawAmount / 100000000
                : rawAmount;

            final double rawFee = double.tryParse(tx['fee'].toString()) ?? 0.0;
            final double fee = coin == 'BTC' ? rawFee / 100000000 : rawFee;

            final double total = amount + fee;

            if (widget.coin.toUpperCase() == 'USDT') {
              return _TransactionSummary(
                txData: tx,
                onBack: () {
                  if (!mounted) return;
                  // Optional refetch, but Homepage will handle its own
                  // context.read<FetchdataBloc>().add(FetchUserDataEvent(email: widget.userInfo['email']));

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Homepage(
                        email: widget.userInfo['email'],
                        wallets: widget.walletInfo,
                        userInfo: widget.userInfo,
                        address: lastSentAddress,
                        pendingOutgoingBtc: 0.0,
                        pendingOutgoingUsdt: widget.amount,
                      ),
                    ),
                    (route) => false,
                  );
                },
              );
            } else {
              final updatedWallet = {
                ...widget.walletInfo,
                'balance_sats':
                    updatedWalletInfo['balance_sats'] ??
                    widget.walletInfo['balance_sats'],
              };
              return _TransactionSummary(
                txData: tx,
                onBack: () {
                  if (!mounted) return;
                  // Optional refetch, but Homepage will handle its own
                  // context.read<FetchdataBloc>().add(FetchUserDataEvent(email: widget.userInfo['email']));
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Homepage(
                        email: widget.userInfo['email'],
                        wallets: updatedWallet,
                        userInfo: widget.userInfo,
                        address: lastSentAddress,
                        pendingOutgoingBtc: widget.amount,
                        pendingOutgoingUsdt: 0.0,
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
            email: widget.userInfo['email'], userInfo: widget.userInfo, fromAddress:widget.fromAddress, toAddress:widget.toAddress, amount: widget.amount, previewData: widget.previewData, coin:widget.coin, walletInfo: widget.walletInfo,
          );
        },
      ),
    );
  }
}

class _PinInput extends StatelessWidget {
  final String email;
  final void Function(String) onPinCompleted;
  final TextEditingController controller;
  final Map<String, dynamic> userInfo;
  final String fromAddress;
  final String toAddress;
  final double amount;
  final Map<String, dynamic> previewData;
  final String coin;
  final Map<String, dynamic> walletInfo;

  const _PinInput({
    required this.onPinCompleted,
    required this.controller,
    required this.email, required this.userInfo, required this.fromAddress, required this.toAddress, required this.amount, required this.previewData, required this.coin, required this.walletInfo,
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
              child: Text(
                'Forgotten Pin? ',
                style: TextStyle(color: kmainWhitecolor),
              ),
            ),
           Padding(
  padding: const EdgeInsets.only(left: 2, top: 8),
  child: GestureDetector(
    onTap: () async {
      try {
        await UserService().resetTransactionPin(email);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A reset PIN email has been sent to your inbox.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPinOtpScreen(email: email, userInfo:userInfo, fromAddress: fromAddress, toAddress: toAddress, amount: amount, previewData: previewData,coin: coin, walletInfo: walletInfo,),
      ),
    );

          
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send reset link. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }, 
    child: Text(
      'Reset Pin',
      style: TextStyle(color: kwhitecolor),
    ),
  ),
)

          ],
        ),
      ],
    );
  }
}

class _TransactionSummary extends StatelessWidget {
  final Map<String, dynamic> txData;
  final VoidCallback onBack;

  _TransactionSummary({required this.txData, required this.onBack});

  final NumberFormat btcFormat = NumberFormat('#,##0.########', 'en_US');
  final NumberFormat usdtFormat = NumberFormat('#,##0.00', 'en_US');

  double _parseFee(dynamic rawFee) {
    if (rawFee == null) return 0.0;

    if (rawFee is int) return rawFee / 100000000;

    final parsed = double.tryParse(rawFee.toString());
    return parsed != null ? parsed / 100000000 : 0.0;
  }

  String formatAmount(double value, String coin) {
    if (coin == 'USDT') return '${usdtFormat.format(value)} USDT';
    return '${btcFormat.format(value)} BTC';
  }

  @override
  Widget build(BuildContext context) {
    final String coin = txData['coin']?.toString().toUpperCase() ?? 'USDT';
    final double amount = double.tryParse(txData['amount'].toString()) ?? 0.0;
    final double fee = _parseFee(txData['fee']);
    final double total = amount + fee;

    return Column(
      children: [
        AnimatedVerifyIconPopup(),
        SizedBox(
          height: 350,
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
                      style: TextStyle(color: kmainWhitecolor),
                    ),
                    Text(
                      'To: ${txData['toAddress'] ?? 'N/A'}',
                      style: TextStyle(color: kmainWhitecolor),
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Amount sent : ${formatAmount(amount, coin)}',
                        style: TextStyle(color: kmainWhitecolor),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      'TxID: ${txData['txid'] ?? 'N/A'}',
                      style: TextStyle(
                        color: kmainWhitecolor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: onBack,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kwhitecolor,
                            ),
                            child: Text(
                              'Back to Homepage',
                              style: TextStyle(color: kmainWhitecolor),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ksubcolor,
                            ),
                            child: Text(
                              'Share Receipt',
                              style: TextStyle(color: kwhitecolor),
                            ),
                          ),
                        ],
                      ),
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
