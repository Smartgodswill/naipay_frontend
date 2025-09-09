// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class Recievefundscreen extends StatefulWidget {
  final Map<String, dynamic> walletData;
  final Map<String, dynamic> userInfo;
  const Recievefundscreen({
    super.key,
    required this.walletData,
    required this.userInfo,
  });

  @override
  State<Recievefundscreen> createState() => _RecievefundscreenState();
}

String selectedCurrency = 'Bitcoin'?? '';

class _RecievefundscreenState extends State<Recievefundscreen> {
  final  TextEditingController ammountController = TextEditingController();

 void shareBitcoinRequest(String address, String amount) {
  String formattedAmount = amount.trim();

  if (selectedCurrency == 'Dollar') {
    formattedAmount = '\$$formattedAmount';
  } else {
    formattedAmount = '$formattedAmount BTC';
  }

  final message = '''
Naipay Request 🟡

Send $formattedAmount to:
→ $address
''';

  Share.share(message);
}

  @override
  Widget build(BuildContext context) {
    final qrData = selectedCurrency == 'Bitcoin'
        ? widget.walletData['bitcoin_address']?? ''
        : widget.userInfo['usdtAddress']?? '';
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Recieve Funds',style: TextStyle(
          color: kmainWhitecolor,
          fontSize: 20
        ),),
        backgroundColor: kmainBackgroundcolor,
        iconTheme: IconThemeData(color: kmainWhitecolor),
      ),
      backgroundColor: kmainBackgroundcolor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            SizedBox(
              width: 400,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: customButtonContainer(
                      60,
                      170,
                      BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 5,
                            blurStyle: BlurStyle.solid,
                            spreadRadius: 0.9,
                            color: kwhitecolor,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(15),
                        color: selectedCurrency == 'Bitcoin'
                            ? const Color.fromARGB(118, 172, 169, 169)
                            : kmainBackgroundcolor,
                      ),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'asset/bitcoinicon.svg',
                            color: const Color.fromARGB(255, 222, 152, 21),
                            height: 60,
                          ),
                          Text(
                            'Bitcoin',
                            style: TextStyle(
                              color: kmainWhitecolor,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      () {
                        setState(() {
                          selectedCurrency = 'Bitcoin';
                        });
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: kwhitecolor,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.amber,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Note:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: kmainWhitecolor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This address only receives funds on the Bitcoin Onchain network.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: kmainWhitecolor,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(Icons.check_circle_outline),
                                      label: Text('Got it!'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: customButtonContainer(
                      60,
                      170,
                      BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 5,
                            blurStyle: BlurStyle.solid,
                            spreadRadius: 0.9,
                            color: kwhitecolor,
                          ),
                        ],
                        color: selectedCurrency == 'Dollar'
                            ? const Color.fromARGB(118, 172, 169, 169)
                            : kmainBackgroundcolor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: SvgPicture.asset(
                              'asset/usdticon.svg',
                              height: 43,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              'Dollar',
                              style: TextStyle(
                                color: kmainWhitecolor,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      () {
                        setState(() {
                          selectedCurrency = 'Dollar';
                        });
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: kwhitecolor,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.amber,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Note:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: kmainWhitecolor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This address only receives funds on the TRC20 network.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: kmainWhitecolor,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(Icons.check_circle_outline),
                                      label: Text('Got it!'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
            SizedBox(
              width: 330,
              child: Stack(
                children: [
                  customContainer(
                    300,
                    size.width * 0.9,
                    BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 5,
                          blurStyle: BlurStyle.solid,
                          spreadRadius: 0.9,
                          color: kwhitecolor,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(20),
                      color: kmainBackgroundcolor,
                    ),
                    Column(
                      children: [
                        Text(
                          selectedCurrency == 'Bitcoin'
                              ? "Scan to receive Bitcoin"
                              : "Scan to receive USDT",
                          style: TextStyle(
                            color: kwhitecolor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        QrImageView(
                          backgroundColor: kmainWhitecolor,
                          data: qrData,
                          size: 250,
                          version: QrVersions.auto,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25, top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Address:',
                    style: TextStyle(color: kmainWhitecolor),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: qrData));
                      },
                      icon: Icon(Icons.copy_all, color: kmainWhitecolor),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 340,
              child: customContainer(
                60,
                size.width * 1,
                BoxDecoration(
                  color: kmainBackgroundcolor,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 5,
                      blurStyle: BlurStyle.solid,
                      spreadRadius: 0.9,
                      color: kwhitecolor,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(20),
                ),
                Center(
                  child: Text(qrData, style: TextStyle(color: kwhitecolor)),
                ),
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8),
                  child: Text(
                    'Request a specific amount(optional):',
                    style: TextStyle(color: kmainWhitecolor),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 340,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: customContainer(
                  60,
                  size.width * 1,
                  BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 5,
                        blurStyle: BlurStyle.solid,
                        spreadRadius: 0.9,
                        color: kwhitecolor,
                      ),
                    ],
                    color: kmainBackgroundcolor,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      controller: ammountController,
                      style: TextStyle(color: kwhitecolor),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(color: kwhitecolor),
                        hintText: 'E.g:  0.0900 BTC or \$25,00',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: FloatingActionButton.small(
                    onPressed: () {
                      shareBitcoinRequest(qrData, ammountController.text);
                      ammountController.clear();
                    },
                    backgroundColor: kwhitecolor,
                    child: Icon(Icons.share, color: kmainWhitecolor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
