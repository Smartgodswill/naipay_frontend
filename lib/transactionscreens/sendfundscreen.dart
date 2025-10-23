// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/services/walletservice.dart';
import 'package:naipay/state%20management/sendtransactionpin/bloc/sendtransactionpin_bloc.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/transactionscreens/verifytransactionpinscreen.dart';
import 'package:naipay/utils/utils.dart';

class Sendfundscreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  final String coin;
  final double balance;
  final double usdtEquivalent;
  final double updatedBal;
  final Map<String, dynamic> wallets;

  Sendfundscreen({
    super.key,
    required this.userInfo,
    required this.coin,
    required this.usdtEquivalent,
    required this.balance,
    required this.wallets,
    required this.updatedBal,
  });

  @override
  State<Sendfundscreen> createState() => _SendfundscreenState();
}

class _SendfundscreenState extends State<Sendfundscreen> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final formatter = NumberFormat('#,##0.00000000', 'en_US');

  bool isAddressValid = false;
  String addressError = '';
  String amountError = '';
  double? estimatedFee;
  @override
  void initState() {
    super.initState();
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScanQRScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        addressController.text = result;
      });
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  bool _isCalculatingFee = false;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Send ${widget.coin}',
          style: TextStyle(color: kmainWhitecolor, fontSize: 20),
        ),
        iconTheme: IconThemeData(color: kmainWhitecolor),
        backgroundColor: kmainBackgroundcolor,
      ),
      backgroundColor: kmainBackgroundcolor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              '${widget.balance} ${widget.coin}',
              style: TextStyle(color: kwhitecolor, fontSize: 25),
            ),
            const SizedBox(height: 45),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25, bottom: 5),
                  child: Text(
                    'Enter recipient ${widget.coin} address',
                    style: TextStyle(color: kmainWhitecolor),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 340,
                child: TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: 'Recipient ${widget.coin} Address',
                    suffixIcon: IconButton(
                      onPressed: _scanQR,
                      icon: Icon(Icons.qr_code_scanner, color: kmainWhitecolor),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    errorText: addressError.isNotEmpty ? addressError : null,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  style: TextStyle(color: kmainWhitecolor),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25, bottom: 5),
                  child: Text(
                    'Enter ${widget.coin} amount',
                    style: TextStyle(color: kmainWhitecolor),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 340,
                child: TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  controller: amountController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,8}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter ${widget.coin} Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    errorText: amountError.isNotEmpty ? amountError : null,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  style: TextStyle(color: kmainWhitecolor),
                ),
              ),
            ),

            const SizedBox(height: 25),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25, bottom: 5),
                  child: Text(
                    'Notepad (optional)',
                    style: TextStyle(color: kmainWhitecolor),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 340,
                child: TextFormField(
                  controller: noteController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter a short Note(optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  style: TextStyle(color: kmainWhitecolor),
                ),
              ),
            ),
            const SizedBox(height: 40),
            customButtonContainer(
              40,
              250,
              BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _isCalculatingFee ? Colors.grey : kwhitecolor,
              ),
              Center(
                child: _isCalculatingFee
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kmainWhitecolor,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Calculating fee...',
                            style: TextStyle(color: kmainWhitecolor),
                          ),
                        ],
                      )
                    : Text('Send', style: TextStyle(color: kmainWhitecolor)),
              ),
              () async {
                if (_isCalculatingFee) return; // prevent double clicks

                final coinType = widget.coin.toUpperCase();

                if (addressController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  customSnackBar('Please fill in address and amount', context);
                  return;
                }

                final amountValue = double.tryParse(
                  amountController.text.trim(),
                );
                if (amountValue == null || amountValue <= 0) {
                  customSnackBar('Please enter a valid amount', context);
                  return;
                }

                setState(() => _isCalculatingFee = true);

                await Future.delayed(Duration.zero);
                try {
                  if (coinType == 'BTC') {
                    await showConfirmBottomSheet(
                      context,
                      userMnemonic: widget.userInfo['mnemonic'],
                      recipientAddress: addressController.text.trim(),
                      amountInBtc: amountValue,
                      coin: 'BTC',
                      userInfo: widget.userInfo,
                      fromAddress: widget.wallets['bitcoin_address'],
                      walletInfo: widget.wallets,
                    );
                  } else if (coinType == 'USDT') {
                    await showUsdtSummaryBottomSheet(
                      context,
                      email: widget.userInfo['email'],
                      toAddress: addressController.text.trim(),
                      amount: amountValue,
                      userInfo: widget.userInfo,
                      walletInfo: widget.wallets,
                    );
                  } else {
                    customSnackBar('Coin type not supported yet', context);
                  }
                } finally {
                  if (mounted) setState(() => _isCalculatingFee = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

final formatter = NumberFormat('#,##0.########', 'en_US');
Future<void> showConfirmBottomSheet(
  BuildContext context, {
  required String userMnemonic,
  required String recipientAddress,
  required double amountInBtc,
  required String fromAddress,
  String? note,
  Map<String, dynamic>? userInfo,
  required String coin,
  required Map<String, dynamic>? walletInfo,
}) async {
  try {
    final int amountInSats = (amountInBtc * 100000000).round();
    print('Converting amount: $amountInBtc BTC to $amountInSats sats');

    final previewData = await WalletService().previewTransaction(
      userMnemonic: userMnemonic,
      recipientAddress: recipientAddress.trim(),
      amountInSats: amountInSats,
    );

    final fee = previewData['fee'] as int;
    final amount = previewData['amount'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return customContainer(
          500,
          600,
          BoxDecoration(color: kmainBackgroundcolor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                backgroundColor: ktransparentcolor,
                iconTheme: IconThemeData(color: kmainWhitecolor),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: Icon(Icons.close, color: kmainWhitecolor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Summary',
                  style: TextStyle(color: kmainWhitecolor, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              _infoRow(
                "Amount:",
                "${formatter.format(amount / 100000000)} BTC",
              ),
              _infoRow("Recipient Address:", recipientAddress),
              _infoRow("Fee:", "${formatter.format(fee / 100000000)} BTC"),
              _infoRow(
                "Total:",
                "${formatter.format((amount / 100000000) + (fee / 100000000))} BTC",
              ),
              if (note != null && note.isNotEmpty) _infoRow("Note", note),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: customButtonContainer(
                        40,
                        150,
                        BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: ksubcolor,
                        ),
                        Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: kmainBackgroundcolor),
                          ),
                        ),
                        () async {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: customButtonContainer(
                        40,
                        150,
                        BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: kwhitecolor,
                        ),
                        Center(
                          child: Text(
                            'Confirm',
                            style: TextStyle(color: kmainWhitecolor),
                          ),
                        ),
                        () async {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  BlocProvider<SendtransactionpinBloc>(
                                    create: (_) => SendtransactionpinBloc(),
                                    child: SetTransactionPinView(
                                      userInfo: userInfo ?? {},
                                      amount: amountInBtc,
                                      previewData: {
                                        ...previewData,
                                        'amount': amountInBtc,
                                        'fee': fee 
                                      },
                                      coin: coin,
                                      walletInfo: walletInfo ?? {},
                                      fromAddress: fromAddress,
                                      toAddress: recipientAddress,
                                    ),
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  } catch (e) {
    if (!context.mounted) return;
    print('Transaction preview error: $e');
    customSnackBar('Transaction failed: $e', context);
  }
}

Future<void> showUsdtSummaryBottomSheet(
  BuildContext context, {
  required String email,
  required String toAddress,
  required double amount,
  required Map<String, dynamic> userInfo,
  required Map<String, dynamic> walletInfo,
  String? note,
}) async {
  double fee = 0;
  bool isLoading = true;

  try {
    fee = await UserService().fetchUsdtFee(
      email: email,
      toAddress: toAddress,
      amount: amount,
    );
    print('Debug - USDT Amount: $amount, Fee: $fee'); // Add debug print
  } catch (e) {
    print('Error fetching fee: $e');
    fee = 0;
    if (!context.mounted) return;
    customSnackBar('Failed to fetch fee: $e', context);
  } finally {
    isLoading = false;
  }

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kmainBackgroundcolor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Summary',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              Center(child: CircularProgressIndicator(color: kmainWhitecolor))
            else ...[
              _infoRow("Amount", "$amount USDT"),
              _infoRow("To Address", toAddress),
              _infoRow("Fee", "${formatter.format(fee)} USDT"),
              if (note != null && note.isNotEmpty) _infoRow("Note", note),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: customButtonContainer(
                    40,
                    150,
                    BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: ksubcolor,
                    ),
                    Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: kmainBackgroundcolor),
                      ),
                    ),
                    () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: customButtonContainer(
                    40,
                    150,
                    BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: kwhitecolor,
                    ),
                    Center(
                      child: Text(
                        'Confirm',
                        style: TextStyle(color: kmainWhitecolor),
                      ),
                    ),
                    isLoading
                        ? () {} // Disable button while loading
                        : () async {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    BlocProvider<SendtransactionpinBloc>(
                                      create: (_) => SendtransactionpinBloc(),
                                      child: SetTransactionPinView(
                                        userInfo: userInfo,
                                        amount: amount, // Ensure this is 60.0
                                        previewData: {
                                          'amount': amount,
                                          'fee': fee,
                                          'toAddress': toAddress,
                                          'note': note,
                                        },
                                        coin: 'USDT',
                                        walletInfo: walletInfo,
                                        fromAddress:
                                            walletInfo['usdt_address'] ?? '',
                                        toAddress: toAddress,
                                      ),
                                    ),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    ),
  );
}
