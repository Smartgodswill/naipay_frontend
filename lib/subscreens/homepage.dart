// ignore_for_file: sort_child_properties_last, unnecessary_string_interpolations, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/state%20management/fetchdata/bloc/fetchdata_bloc.dart';
import 'package:naipay/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naipay/transactionscreens/recievefundscreen.dart';
import 'package:naipay/utils/utils.dart';

class Homepage extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? wallets;
  final Map<String, dynamic>? userInfo;
  const Homepage({super.key, required this.email, this.wallets, this.userInfo});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool hasFetched = false;
  bool visble = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentState = context.read<FetchdataBloc>().state;
    if (!hasFetched && currentState is! FetchUsersSuccessState) {
      context.read<FetchdataBloc>().add(
        FetchUserDataEvent(email: widget.email),
      );
      hasFetched = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: BlocConsumer<FetchdataBloc, FetchdataState>(
        listener: (context, state) {
          if (state is FetchUsersFailureState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              customDialog(
                context,
                'FetchUsersFailureState triggered with message: ${state.message}',
              );
            });
          }
        },
        builder: (context, state) {
          // Extract data only if success
          final wallet =
              (state is FetchUsersSuccessState && state.walletdata != null)
              ? state.walletdata
              : widget.wallets;

          final userinfo =
              widget.userInfo ??
              (state is FetchUsersSuccessState ? state.usersInfo : null);
          final price = (state is FetchUsersSuccessState) ? state.prices : null;
          final cryptoCharts = (state is FetchUsersSuccessState)
              ? state.chartData
              : null;
          final isUpwards = (state is FetchUsersSuccessState)
              ? state.isUpward
              : null;
          double balanceBtc = 0.0;

          if (wallet != null) {
            if (wallet['balance_sats'] is int) {
              balanceBtc = wallet['balance_sats'] / 100000000;
            } else if (wallet['balance_sats'] is String) {
              int satoshis = int.tryParse(wallet['balance_sats']) ?? 0;
              balanceBtc = satoshis / 100000000;
            }
          }

          // Format to 8 decimal places
          String balanceDisplay = '${balanceBtc.toStringAsFixed(8)}BTC';

          return RefreshIndicator(
            onRefresh: () async {
              context.read<FetchdataBloc>().add(
                FetchUserDataEvent(email: widget.email),
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 45,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customButtonContainer(
                      60,
                      size.width,
                      BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              foregroundColor: kmainWhitecolor,
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.add_a_photo_outlined),
                              ),
                              radius: 25,
                              backgroundColor: kwhitecolor,
                            ),
                          ),
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  userinfo != null
                                      ? 'Hi, ${userinfo['name']}'
                                      : 'Hi, User',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: kwhitecolor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                'Welcome!',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: kmainWhitecolor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.only(left: 50),
                            child: IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.qr_code_2,
                                size: 30,
                                color: kmainWhitecolor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.notifications,
                              size: 30,
                              color: kmainWhitecolor,
                            ),
                          ),
                        ],
                      ),
                      () {},
                    ),

                    const SizedBox(height: 30),
                    customContainer(
                      size.height / 5.9,
                      350,
                      BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 5,
                            blurStyle: BlurStyle.solid,
                            spreadRadius: 0.9,
                            color: kwhitecolor,
                          ),
                        ],
                        color: kmainBackgroundcolor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Text(
                                  'Bitcoin Balance:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: kmainWhitecolor,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    visble = !visble;
                                  });
                                },
                                icon: visble
                                    ? Icon(
                                        Icons.visibility,
                                        color: ksubbackgroundcolor,
                                      )
                                    : Icon(
                                        Icons.visibility_off,
                                        color: ksubbackgroundcolor,
                                      ),
                              ),
                            ],
                          ),

                          if (wallet != null)
                            Text(
                              visble ? balanceDisplay.toString() : '*********',
                              style: TextStyle(
                                fontSize: 23,
                                color: kmainWhitecolor,
                              ),
                            )
                          else
                            Text(
                              '---',
                              style: TextStyle(
                                fontSize: 50,
                                color: kwhitecolor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    customContainer(
                      size.height / 15,
                      350,
                      BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 5,
                            blurStyle: BlurStyle.solid,
                            spreadRadius: 0.9,
                            color: kwhitecolor,
                          ),
                        ],
                        color: kmainBackgroundcolor,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  'USDT Balance:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: kmainWhitecolor,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.visibility,
                                  color: ksubbackgroundcolor,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 30),
                                child: Text(
                                  "\$59,000,000,000,000",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: kmainWhitecolor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      child: SizedBox(
                        width: 350,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    child: Center(
                                      child: Icon(
                                        Icons.monetization_on_outlined,
                                        size: 30,
                                        color: kwhitecolor,
                                      ),
                                    ),
                                    radius: 25,
                                    backgroundColor: ksubcolor,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Deposit',
                                    style: TextStyle(color: kwhitecolor),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'asset/convert.svg',
                                        color: kwhitecolor,
                                        height: 30,
                                        width: 30,
                                      ),
                                    ),
                                    backgroundColor: ksubcolor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Swap',
                                    style: TextStyle(color: kwhitecolor),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: ksubcolor,
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'asset/send.svg',
                                        color: kwhitecolor,
                                        height: 30,
                                        width: 30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Send',
                                    style: TextStyle(color: kwhitecolor),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return Recievefundscreen(
                                              walletData: wallet ?? {},
                                              userInfo: userinfo ?? {},
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: ksubcolor,
                                      child: Center(
                                        child: SvgPicture.asset(
                                          'asset/getfunds.svg',
                                          color: kwhitecolor,
                                          height: 30,
                                          width: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Recieve',
                                    style: TextStyle(color: kwhitecolor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Market Price:',
                        style: TextStyle(color: kwhitecolor, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: customContainer(
                        100,
                        size.width,
                        BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              blurStyle: BlurStyle.solid,
                              spreadRadius: 0.9,
                              color: kwhitecolor,
                            ),
                          ],
                          color: kmainBackgroundcolor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                  'asset/bitcoinicon.svg',
                                  color: const Color.fromARGB(255, 194, 120, 0),
                                  height: 60,
                                  width: 60,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Text(
                                    'Bitcoin(BTC Price):',
                                    style: TextStyle(
                                      color: kwhitecolor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 20,
                                          ),
                                          child: Text(
                                            price != null
                                                ? '1 BTC = \$${(price['BTC'] ?? 0).toStringAsFixed(2)}'
                                                : 'Loading price...',
                                            style: TextStyle(
                                              color: kwhitecolor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: customContainer(
                        size.height / 9.6,
                        size.width,
                        BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 5,
                              blurStyle: BlurStyle.solid,
                              spreadRadius: 0.9,
                              color: kwhitecolor,
                            ),
                          ],
                          color: kmainBackgroundcolor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        Row(
                          children: [
                            Text(userinfo?['usdtAddress'] ?? 'ejudeuheuh'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
