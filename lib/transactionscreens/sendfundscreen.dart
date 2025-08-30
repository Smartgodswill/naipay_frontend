// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/services/walletservice.dart';
import 'package:naipay/state%20management/sendtransactionpin/bloc/sendtransactionpin_bloc.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/transactionscreens/settransactionpinscreen.dart';
import 'package:naipay/utils/utils.dart';

class Sendfundscreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  final String coin;
  final double balance;
  final double usdtEquivalent;
  final Map<String, dynamic> wallets;

  Sendfundscreen({
    super.key,
    required this.userInfo,
    required this.coin,
    required this.usdtEquivalent,
    required this.balance,
    required this.wallets,
  });

  @override
  State<Sendfundscreen> createState() => _SendfundscreenState();
}

class _SendfundscreenState extends State<Sendfundscreen> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final formatter = NumberFormat('#,##0.00', 'en_US');

  bool isAddressValid = false;
  String addressError = '';
  String amountError = '';
  double? estimatedFee; // Store the USDT fee
  String baseUrl =
      'https://your-api-base-url.com'; // Replace with your actual base URL

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Bal:   ${widget.balance} ${widget.coin}",
                  style: TextStyle(color: kmainWhitecolor, fontSize: 20),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "= ${formatter.format(widget.usdtEquivalent)} USDT",
                  style: TextStyle(color: kwhitecolor, fontSize: 10),
                ),
              ],
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

                // ✅ Start loading immediately
                setState(() => _isCalculatingFee = true);

                // ✅ Let the UI rebuild before showing the modal
                await Future.delayed(Duration.zero);
                try {
                  if (coinType == 'BTC') {
                    // ✅ Await the modal
                    await showConfirmBottomSheet(
                      context,
                      userMnemonic: widget.userInfo['mnemonic'],
                      recipientAddress: addressController.text.trim(),
                      amountInBtc: amountValue,
                      coin: 'BTC',
                      userInfo: widget.userInfo,
                      fromAddress: widget.wallets['bitcoin_address'],
                      walletInfo: widget.wallets
                    );
                  } else if (coinType == 'USDT') {
                    await showUsdtSummaryBottomSheet(
                      context,
                      email: widget.userInfo['email'],
                      toAddress: addressController.text.trim(),
                      amount: amountValue,
                    );
                  } else {
                    customSnackBar('Coin type not supported yet', context);
                  }
                } finally {
                  // ✅ Stop loading once bottom sheet is shown or error occurs
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
    // Convert to sats
    final int amountInSats = (amountInBtc * 100000000).round();
    print('Converting amount: $amountInBtc BTC to $amountInSats sats');

    // Call preview directly
    final previewData = await WalletService().previewTransaction(
      userMnemonic: userMnemonic,
      recipientAddress: recipientAddress.trim(),
      amountInSats: amountInSats,
    );

    final fee = previewData['fee'] as int;
    final amount = previewData['amount'] as int;
    print(fee);
    print(amount);
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
              _infoRow(" Recieptiant Address:", recipientAddress),
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
                          Navigator.pop(
                            context,
                          ); // Close the bottom sheet first
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  BlocProvider<SendtransactionpinBloc>(
                                    create: (_) =>
                                        SendtransactionpinBloc(), // Assuming the bloc constructor doesn't need params; adjust if it does
                                    child: SetTransactionPinView(
                                      userInfo: userInfo ?? {},
                                      toaddress: recipientAddress,
                                      amount: amount,
                                      previewData: previewData,
                                      coin: coin,
                                      walletInfo:walletInfo?? {} ,
                                      fromAddress: fromAddress,
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
  String? note,
}) async {
  double fee = 0;

  try {
    // Fetch fee dynamically
    fee = await UserService().fetchUsdtFee(
      email: email,
      toAddress: toAddress,
      amount: amount,
    );
  } catch (e) {
    // Handle error if fee cannot be fetched
    print('Error fetching fee: $e');
    fee = 0;
  }

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

            _infoRow("Amount", "$amount USDT"),
            _infoRow("ToAddress", toAddress),
            _infoRow("Fee", "${fee.toStringAsFixed(6)} USDT"),
            if (note != null && note.isNotEmpty) _infoRow("Note", note),
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
                        () async {
                          Navigator.pop(context);
                        },
                      ),
                    ),
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
                            'Confirm',
                            style: TextStyle(color: kmainBackgroundcolor),
                          ),
                        ),
                        () async {
                          Navigator.pop(context);
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
