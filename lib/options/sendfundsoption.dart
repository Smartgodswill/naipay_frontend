import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naipay/state%20management/pricesbloc/prices_bloc.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/transactionscreens/sendfundscreen.dart'; 
import 'package:naipay/transactionscreens/settransactipnpinscreen.dart';
import 'package:naipay/utils/utils.dart';

Widget sendfundsoption(
  BuildContext context,
  Map<String, dynamic> userInfo,
  Map<String, dynamic>? wallet,
  double balanceBtc,
  double usdtBalances,
  String email,
) {
  final size = MediaQuery.of(context).size;

  return BottomSheet(
    backgroundColor: ktransparentcolor,
    onClosing: () {},
    enableDrag: false, // Disable dragging to fix animationController error
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: kmainBackgroundcolor,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Non-scrollable, fits content
          children: [
            const SizedBox(height: 20),
            Text(
              'Choose the network you’d like to send on',
              style: TextStyle(
                color: kmainWhitecolor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),

            // BTC Option
            SizedBox(
              height: 70,
              child: _buildcontainer(
                size.height / 12.5,
                size.width * 0.9,
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: SvgPicture.asset(
                        'asset/bitcoinicon.svg',
                        color: kbitcoincolor,
                        height: 60,
                        width: 50,
                      ),
                    ),
                    Text(
                      'Bitcoin (Onchain network)',
                      style: TextStyle(
                        color: kmainWhitecolor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                () {
                  Navigator.pop(context);

                  final pricesBloc = context.read<PricesBloc>();
                  double btcPriceInUsdt = 0.0;
                  if (pricesBloc.state is PricesLoadedSuccessState) {
                    btcPriceInUsdt = (pricesBloc.state as PricesLoadedSuccessState)
                            .prices['BTC']?['price']
                            ?.toDouble() ??
                        0.0;
                  }
                  double usdtEquivalent = balanceBtc * btcPriceInUsdt;

                  _navigateWithPinCheck(
                    context,
                    userInfo,
                    email,
                    wallet,
                    'BTC',
                    balanceBtc,
                    usdtEquivalent,
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // USDT Option
            SizedBox(
              height: 70,
              child: _buildcontainer(
                size.height / 12.5,
                size.width * 0.9,
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SvgPicture.asset(
                            'asset/usdticon.svg',
                            height: 45,
                            width: 45,
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: SvgPicture.asset(
                              'asset/tron.svg',
                              height: 16,
                              width: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'USDT (TRC20 network)',
                      style: TextStyle(
                        color: kmainWhitecolor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                () {
                  Navigator.pop(context);

                  _navigateWithPinCheck(
                    context,
                    userInfo,
                    email,
                    wallet,
                    'USDT',
                    usdtBalances,
                    usdtBalances, // USDT is 1:1
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

void _navigateWithPinCheck(
  BuildContext context,
  Map<String, dynamic> userInfo,
  String email,
  Map<String, dynamic>? wallet,
  String coin,
  double balance,
  double usdtEquivalent,
) {
  if (userInfo['hasTransactionPin'] == false) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetTransactionPinScreen(email: email,userinfo: userInfo,coin: coin,balance: balance,usdtEquivalent: usdtEquivalent,wallets: wallet??{},),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Sendfundscreen(
          wallets: wallet ?? {},
          userInfo: userInfo,
          coin: coin,
          balance: balance,
          usdtEquivalent: usdtEquivalent,
        ),
      ),
    );
  }
}

Widget _buildcontainer(
  double height,
  double width,
  Widget child,
  Function()? ontap,
) {
  return customButtonContainer(
    height,
    width,
    BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: kmainBackgroundcolor,
      boxShadow: [
        BoxShadow(
          color: kwhitecolor,
          blurStyle: BlurStyle.solid,
          blurRadius: 5,
          spreadRadius: 0.9,
        ),
      ],
    ),
    child,
    ontap,
  );
}
