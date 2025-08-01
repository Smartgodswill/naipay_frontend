// ignore_for_file: sort_child_properties_last, unnecessary_string_interpolations, deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/state%20management/fetchdata/bloc/fetchdata_bloc.dart';
import 'package:naipay/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naipay/utils/utils.dart';

class Homepage extends StatefulWidget {
  final String email;
  const Homepage({super.key, required this.email});

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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ksubbackgroundcolor,
      body: BlocConsumer<FetchdataBloc, FetchdataState>(
        listener: (context, state) {
          if (state is FetchUsersFailureState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              customDialog(context, state.message);
            });
          }
        },
        builder: (context, state) {
          // Extract data only if success
          final wallet = (state is FetchUsersSuccessState)
              ? state.walletdata
              : null;
          final userinfo = (state is FetchUsersSuccessState)
              ? state.usersInfo
              : null;
          final price = (state is FetchUsersSuccessState) ? state.prices : null;
          final cryptoCharts = (state is FetchUsersSuccessState)
              ? state.chartData
              : null;
          final isUpwards = (state is FetchUsersSuccessState)
              ? state.isUpward
              : null;
          int balance = 0;
          if (wallet != null) {
            if (wallet['balance_sats'] is int) {
              balance = wallet['balance_sats'];
            } else if (wallet['balance_sats'] is String) {
              balance = int.tryParse(wallet['balance_sats']) ?? 0;
            }
          }

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
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.add_a_photo_outlined),
                              ),
                              radius: 25,
                              backgroundColor: ksubcolor,
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
                                  color: kwhitecolor,
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
                              icon: const Icon(Icons.qr_code_2, size: 30),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications, size: 30),
                          ),
                        ],
                      ),
                      () {},
                    ),

                    const SizedBox(height: 30),
                    customContainer(
                      size.height / 4.8,
                      400,
                      BoxDecoration(
                        color: kmainBackgroundcolor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Wallet Balance:',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: kwhitecolor,
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
                          if (state is FetchUsersLoadingState)
                            CircularProgressIndicator(
                              color: ksubbackgroundcolor,
                              padding: EdgeInsetsDirectional.all(20),
                            )
                          else if (wallet != null)
                            Text(
                              visble ? balance.toString() : '******',
                              style: TextStyle(
                                fontSize: 50,
                                color: kwhitecolor,
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
                                        color: kmainBackgroundcolor,
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
                                        color: kmainBackgroundcolor,
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
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: ksubcolor,
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'asset/getfunds.svg',
                                        color: kmainBackgroundcolor,
                                        height: 30,
                                        width: 30,
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
                      child: Text('Market Price:',style: TextStyle(color: kwhitecolor,fontSize: 18),),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: customContainer(
                        size.height/8.5,
                        size.width,
                        BoxDecoration(
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
                                  child: Text('Bitcoin(BTC Price):',style: TextStyle(
                                    color: kwhitecolor,
                                    fontWeight: FontWeight.w600
                                  ),),
                                ),
                                const SizedBox(width: 8),
                            
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 20),
                                          child: Text(
                                            price != null
                                                ? '1 BTC = \$${(price['BTC'] ?? 0).toStringAsFixed(2)}'
                                                : 'Loading price...',
                                            style: TextStyle(color: kwhitecolor),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        isUpwards != null
                                            ? Icon(
                                                isUpwards
                                                    ? Icons.trending_up
                                                    : Icons.trending_down,
                                                color: isUpwards
                                                    ? Colors.green
                                                    : Colors.red,
                                                    size: 30,
                                              )
                                            : Padding(
                                                padding: EdgeInsets.all(10),
                                                child: CircularProgressIndicator(),
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
                          color: kmainBackgroundcolor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        Row(children: []),
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
