// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:naipay/theme/colors.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
Widget customContainer(
  double height,
  double width,
  BoxDecoration decoration,
  Widget? child,
) {
  return Container(
    height: height,
    width: width,
    decoration: decoration,
    child: child,
  );
}

Widget customButtonContainer(
  double height,
  double width,
  BoxDecoration decoration,
  Widget? child,
  Function()? ontap,
) {
  return InkWell(
    onTap: ontap,
    child: Container(
      height: height,
      width: width,
      decoration: decoration,
      child: child,
    ),
  );
}

void customSnackBar(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

customDialog(BuildContext context, String text) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: ksubcolor,
      title: const Text("Oops!"),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

List<String> images = [
  'asset/write.json',
  'asset/play.json',
  'asset/origins.json',
  'asset/learn.json',
];
List<String> earnText = [
  'Write & earn',
  'Play games & earn',
  'Origin of BTC',
  'Learn & get paid',
];




class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: kmainWhitecolor
        ),
        title:  Text('Scan QR Code',style: TextStyle(color: kmainWhitecolor),),backgroundColor: kmainBackgroundcolor,),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.white,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final code = scanData.code;
      if (code != null && mounted) {
        Navigator.pop(context, code); 
      }
    });
  }
}

class MnemonicEncryption {
  final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows!'); // must be 32 chars
  final _iv = encrypt.IV.fromLength(16);

  String encryptMnemonics(String text) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }

  String decryptMnemonics(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}



void showTransactionSuccessCard(BuildContext context, Map<String, dynamic> txData) {
  final formattedDate = DateFormat('yyyy-MM-dd – kk:mm:ss').format(DateTime.now());

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
        height: 400,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                'Transaction Confirmed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(height: 30, thickness: 1),
            _infoRow("From", txData['fromAddress']),
            _infoRow("To", txData['toAddress']),
            _infoRow("Amount", "${txData['amount']} ${txData['coin']}"),
            _infoRow("Fee", "${txData['fee']} ${txData['coin']}"),
            _infoRow("Date & Time", formattedDate),
            _infoRow("TxID", txData['txid']),
            SizedBox(height: 15),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final url = 'https://mempool.space/tx/${txData['txid']}';
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                },
                child: Text('View on Blockchain'),
              ),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}


