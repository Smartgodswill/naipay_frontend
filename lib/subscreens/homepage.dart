// ignore_for_file: sort_child_properties_last, unnecessary_string_interpolations, deprecated_member_use, unnecessary_null_comparison, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/animations/animatedloader.dart';
import 'package:naipay/options/sendfundsoption.dart';
import 'package:naipay/state%20management/pricesbloc/prices_bloc.dart';
import 'package:naipay/state%20management/fetchdata/bloc/fetchdata_bloc.dart';
import 'package:naipay/subscreens/learnpage.dart';
import 'package:naipay/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naipay/transactionscreens/recievefundscreen.dart';
import 'package:naipay/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:bdk_flutter/bdk_flutter.dart';

class Homepage extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? wallets;
  final Map<String, dynamic>? userInfo;
  final Map<String, dynamic>? trc20Transactions;
  const Homepage({
    super.key,
    required this.email,
    this.wallets,
    this.userInfo,
    this.trc20Transactions,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with TickerProviderStateMixin {
  bool hasFetchedUserData = false;
  bool hasFetchedPrices = false;
  bool visble = true;
  bool _hasShownPriceErrorSnackBar = false;
  bool _hasShownUserErrorSnackBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasFetchedPrices) {
        context.read<PricesBloc>().add(FetchPricesEvent());
        hasFetchedPrices = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fetchDataBloc = context.read<FetchdataBloc>();
    if (!hasFetchedUserData && fetchDataBloc.state is FetchdataInitial) {
      fetchDataBloc.add(FetchUserDataEvent( email: widget.userInfo!['email']));
      hasFetchedUserData = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final formatter = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: BlocConsumer<FetchdataBloc, FetchdataState>(
        listener: (context, state) {
          print('Current FetchdataBloc state: $state');
          if (state is FetchUsersFailureState && !_hasShownUserErrorSnackBar) {
            print('Exception: ${state.message}');
           
            _hasShownUserErrorSnackBar = true;
          }
        },
        builder: (context, state) {
          final wallet =
              (state is FetchUsersSuccessState && state.walletdata != null)
              ? state.walletdata
              : widget.wallets;
          final userinfo =
              (state is FetchUsersSuccessState && state.usersInfo != null)
              ? state.usersInfo
              : widget.userInfo;
          final transactionUsdt =
              (state is FetchUsersSuccessState &&
                  state.trc20Transactions != null)
              ? state.trc20Transactions
              : widget.trc20Transactions;

          print('Wallet data: $wallet');
          print('User info: $userinfo');
          print('TRC20 transaction history: $transactionUsdt');
          print(userinfo?['usdtAddress'] ?? 'No USDT address');

          double balanceBtc = 0.0;
          double usdtBalance = 0.0;

          // Calculate balances
          if (wallet != null) {
            if (wallet['balance_sats'] is int) {
              balanceBtc = wallet['balance_sats'] / 100000000;
            } else if (wallet['balance_sats'] is String) {
              int satoshis = int.tryParse(wallet['balance_sats']) ?? 0;
              balanceBtc = satoshis / 100000000;
            }

            usdtBalance = wallet['usdtBalances'] is int
                ? (wallet['usdtBalances'] as int).toDouble()
                : wallet['usdtBalances']?.toDouble() ?? 0.0;
          }

          // Fallback to user info if wallet USDT balance is 0
          if (usdtBalance == 0.0 && userinfo != null) {
            usdtBalance = userinfo['usdtBalances'] is int
                ? (userinfo['usdtBalances'] as int).toDouble()
                : userinfo['usdtBalances']?.toDouble() ?? 0.0;
          }

          print('Bitcoin balance: $balanceBtc BTC');
          print('USDT balance: $usdtBalance USDT');
          String btcBalanceDisplay = '${balanceBtc.toStringAsFixed(8)} BTC';

          // Merge transactions
          List<Map<String, dynamic>> transactions = [];

          // BTC transactions
          if (wallet?['transaction_history'] != null) {
            transactions.addAll(
              (wallet!['transaction_history'] as List<dynamic>).map((tx) {
                final txDetails = tx as TransactionDetails;
                final isSend = txDetails.sent > 0;
                final amountSats = isSend
                    ? txDetails.sent - txDetails.received
                    : txDetails.received;
                final amountBtc = amountSats / 100000000;
                return {
                  'type': isSend ? 'send' : 'receive',
                  'amount': amountBtc,
                  'currency': 'BTC',
                  'time': txDetails.confirmationTime?.timestamp != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          txDetails.confirmationTime!.timestamp * 1000,
                        )
                      : DateTime.now(),
                  'from': isSend ? wallet['bitcoin_address'] : 'Unknown',
                  'to': isSend ? 'Unknown' : wallet['bitcoin_address'],
                  'other_details': 'TxID: ${txDetails.txid}',
                  'status': txDetails.confirmationTime != null
                      ? 'Confirmed'
                      : 'Pending',
                };
              }).toList(),
            );
          }

          // TRC20 transactions
          if (transactionUsdt != null) {
            transactions.addAll(
              (transactionUsdt as List<dynamic>).map((tx) {
                final t = tx as Map<String, dynamic>;
                final amount = t['amount'] is int
                    ? (t['amount'] as int).toDouble()
                    : t['amount'] is double
                    ? t['amount'] as double
                    : 0.0;

                return {
                  'type': t['type'] ?? 'Unknown',
                  'amount': amount,
                  'currency': t['currency'] ?? 'USDT',
                  'time': t['time'] is String
                      ? DateTime.parse(t['time'])
                      : t['time'] is DateTime
                      ? t['time']
                      : DateTime.now(),
                  'from': t['from'] ?? 'Unknown',
                  'to': t['to'] ?? 'Unknown',
                  'other_details': t['other_details'] ?? 'N/A',
                  'status': t['status'] ?? 'Pending', // ✅ use backend status
                };
              }).toList(),
            );
          }

          // Sort by newest first
          transactions.sort((a, b) => b['time'].compareTo(a['time']));

          print('Merged Transactions: $transactions');

          return RefreshIndicator(
            onRefresh: () async {
              hasFetchedUserData = false;
              hasFetchedPrices = false;
              _hasShownPriceErrorSnackBar = false;
              _hasShownUserErrorSnackBar = false;
              context.read<FetchdataBloc>().add(
                FetchUserDataEvent(email: userinfo!['email']),
              );
              context.read<PricesBloc>().add(FetchPricesEvent());
              try {
                print('Starting refresh: ${DateTime.now()}');
                await Future.wait([
                  context
                      .read<FetchdataBloc>()
                      .stream
                      .firstWhere(
                        (state) =>
                            state is FetchUsersSuccessState ||
                            state is FetchUsersFailureState,
                        orElse: () {
                          print('FetchdataBloc timeout');
                          return FetchUsersFailureState(
                            message: 'User data fetch timed out',
                          );
                        },
                      )
                      .timeout(
                        const Duration(seconds: 10),
                        onTimeout: () {
                          print('FetchdataBloc timeout');
                          return FetchUsersFailureState(
                            message: 'User data fetch timed out',
                          );
                        },
                      ),
                  context
                      .read<PricesBloc>()
                      .stream
                      .firstWhere(
                        (state) =>
                            state is PricesLoadedSuccessState ||
                            state is PricesErrorState,
                        orElse: () {
                          print('PricesBloc timeout');
                          return PricesErrorState('Price fetch timed out');
                        },
                      )
                      .timeout(
                        const Duration(seconds: 10),
                        onTimeout: () {
                          print('PricesBloc timeout');
                          return PricesErrorState('Price fetch timed out');
                        },
                      ),
                ]);
                print('Refresh completed: ${DateTime.now()}');
              } catch (e) {
                print('Refresh error: $e');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
              }
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
                                child: SizedBox(
                                  width: 130,
                                  child: Text(
                                    userinfo != null
                                        ? 'Hi, ${userinfo['name']}'
                                        : 'Hi, .......',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: kmainWhitecolor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      top: 28,
                                    ),
                                    child: Text(
                                      'Bitcoin Balance:',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: kmainWhitecolor,
                                      ),
                                    ),
                                  ),
                                  if (state is FetchUsersLoadingState)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: AnimatedLoadingDots(),
                                    )
                                  else if (wallet != null)
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 28,
                                          right: 12,
                                        ),
                                        child: BlocBuilder<PricesBloc, PricesState>(
                                          builder: (context, priceState) {
                                            double btcPriceInUsdt = 0.0;
                                            Widget usdtBalanceDisplay =
                                                AnimatedLoadingDots();

                                            if (priceState
                                                is PricesLoadedSuccessState) {
                                              btcPriceInUsdt =
                                                  priceState
                                                      .prices['BTC']?['price']
                                                      ?.toDouble() ??
                                                  0.0;
                                              double usdtEquivalent =
                                                  balanceBtc * btcPriceInUsdt;
                                              usdtBalanceDisplay = Text(
                                                balanceBtc == 0.0
                                                    ? '0.00 USDT'
                                                    : '${formatter.format(usdtEquivalent)} USDT',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: kwhitecolor,
                                                ),
                                                textAlign: TextAlign.end,
                                              );
                                            } else if (priceState
                                                is PricesLoadingState) {
                                              usdtBalanceDisplay =
                                                  AnimatedLoadingDots();
                                            } else if (priceState
                                                    is PricesErrorState &&
                                                !_hasShownPriceErrorSnackBar) {
                                              usdtBalanceDisplay = Text(
                                                'Price unavailable',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: kwhitecolor,
                                                ),
                                                textAlign: TextAlign.end,
                                              );
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          priceState.message
                                                                  .contains(
                                                                    '429',
                                                                  )
                                                              ? 'Rate limit exceeded. Please try again later.'
                                                              : 'Failed to load prices: ${priceState.message}',
                                                        ),
                                                      ),
                                                    );
                                                    _hasShownPriceErrorSnackBar =
                                                        true;
                                                  });
                                            }

                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                SizedBox(
                                                  width: 250,
                                                  child: Text(
                                                    visble
                                                        ? btcBalanceDisplay
                                                        : '*********',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: kmainWhitecolor,
                                                    ),
                                                    textAlign: TextAlign.end,
                                                  ),
                                                ),
                                                visble
                                                    ? usdtBalanceDisplay
                                                    : Text(
                                                        '*********',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: kwhitecolor,
                                                        ),
                                                        textAlign:
                                                            TextAlign.end,
                                                      ),
                                              ],
                                            );
                                          },
                                        ),
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
                            ],
                          ),
                        ),
                      ],
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  'Tether Balance:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: kmainWhitecolor,
                                  ),
                                ),
                              ),
                              if (state is FetchUsersLoadingState)
                                AnimatedLoadingDots()
                              else
                                Padding(
                                  padding: const EdgeInsets.only(right: 25),
                                  child: visble
                                      ? Text(
                                          "${formatter.format(usdtBalance)} USDT",
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: kmainWhitecolor,
                                          ),
                                        )
                                      : Text(
                                          '********',
                                          style: TextStyle(
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
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Learnpage(),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      child: Center(
                                        child: Icon(
                                          Icons.book_sharp,
                                          size: 30,
                                          color: kwhitecolor,
                                        ),
                                      ),
                                      radius: 25,
                                      backgroundColor: ksubcolor,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'learn',
                                    style: TextStyle(color: kmainWhitecolor),
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
                                    style: TextStyle(color: kmainWhitecolor),
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
                                      showDialog(
                                        context: context,
                                        builder: (context) => sendfundsoption(
                                          context,
                                          userinfo??{},
                                          wallet,
                                          balanceBtc,
                                          usdtBalance,
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
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
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Send',
                                    style: TextStyle(color: kmainWhitecolor),
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
                                          builder: (context) =>
                                              Recievefundscreen(
                                                walletData: wallet ?? {},
                                                userInfo: userinfo ?? {},
                                              ),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: ksubcolor,
                                      child: Center(
                                        child: SvgPicture.asset(
                                          'asset/recieveicon.svg',
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
                                    style: TextStyle(color: kmainWhitecolor),
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
                        style: TextStyle(
                          color: kmainWhitecolor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    BlocBuilder<PricesBloc, PricesState>(
                      builder: (context, priceState) {
                        print('Current PricesBloc state: $priceState');
                        return Column(
                          children: [
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'asset/bitcoinicon.svg',
                                          color: kbitcoincolor,
                                          height: 60,
                                          width: 60,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 1,
                                            top: 4,
                                          ),
                                          child: Text(
                                            'Bitcoin Price:',
                                            style: TextStyle(
                                              color: kmainWhitecolor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        top: 20,
                                      ),
                                      child:
                                          priceState is PricesLoadedSuccessState
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '\$${formatter.format(priceState.prices['BTC']?['price'] ?? 0.0)}',
                                                  style: TextStyle(
                                                    color: kmainWhitecolor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${(priceState.prices['BTC']?['change_24h'] ?? 0.0).toStringAsFixed(2)}%',
                                                      style: TextStyle(
                                                        color:
                                                            (priceState.prices['BTC']?['change_24h'] ??
                                                                    0.0) >=
                                                                0
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Icon(
                                                      (priceState.prices['BTC']?['change_24h'] ??
                                                                  0.0) >=
                                                              0
                                                          ? Icons.arrow_upward
                                                          : Icons
                                                                .arrow_downward,
                                                      color:
                                                          (priceState.prices['BTC']?['change_24h'] ??
                                                                  0.0) >=
                                                              0
                                                          ? Colors.green
                                                          : Colors.red,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'Rank: ${priceState.prices['BTC']?['rank'] ?? 'N/A'}',
                                                  style: TextStyle(
                                                    color: kmainWhitecolor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : priceState is PricesErrorState
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Error: Price unavailable',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (!_hasShownPriceErrorSnackBar)
                                                  Builder(
                                                    builder: (context) {
                                                      WidgetsBinding.instance.addPostFrameCallback((
                                                        _,
                                                      ) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              priceState.message
                                                                      .contains(
                                                                        '429',
                                                                      )
                                                                  ? 'Rate limit exceeded. Please try again later.'
                                                                  : 'Failed to load prices: ${priceState.message}',
                                                            ),
                                                          ),
                                                        );
                                                        _hasShownPriceErrorSnackBar =
                                                            true;
                                                      });
                                                      return SizedBox.shrink();
                                                    },
                                                  ),
                                              ],
                                            )
                                          : AnimatedLoadingDots(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: customContainer(
                                100,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SvgPicture.asset(
                                            'asset/usdticon.svg',
                                            height: 45,
                                            width: 35,
                                          ),
                                        ),
                                        Text(
                                          'Tether Price:',
                                          style: TextStyle(
                                            color: kmainWhitecolor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        top: 20,
                                      ),
                                      child:
                                          priceState is PricesLoadedSuccessState
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '\$${formatter.format(priceState.prices['USDT']?['price'] ?? 0.0)}',
                                                  style: TextStyle(
                                                    color: kmainWhitecolor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${(priceState.prices['USDT']?['change_24h'] ?? 0.0).toStringAsFixed(2)}%',
                                                      style: TextStyle(
                                                        color:
                                                            (priceState.prices['USDT']?['change_24h'] ??
                                                                    0.0) >=
                                                                0
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Icon(
                                                      (priceState.prices['USDT']?['change_24h'] ??
                                                                  0.0) >=
                                                              0
                                                          ? Icons.arrow_upward
                                                          : Icons
                                                                .arrow_downward,
                                                      color:
                                                          (priceState.prices['USDT']?['change_24h'] ??
                                                                  0.0) >=
                                                              0
                                                          ? Colors.green
                                                          : Colors.red,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'Rank: ${priceState.prices['USDT']?['rank'] ?? 'N/A'}',
                                                  style: TextStyle(
                                                    color: kmainWhitecolor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : priceState is PricesErrorState
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Error: Price unavailable',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (!_hasShownPriceErrorSnackBar)
                                                  Builder(
                                                    builder: (context) {
                                                      WidgetsBinding.instance.addPostFrameCallback((
                                                        _,
                                                      ) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              priceState.message
                                                                      .contains(
                                                                        '429',
                                                                      )
                                                                  ? 'Rate limit exceeded. Please try again later.'
                                                                  : 'Failed to load prices: ${priceState.message}',
                                                            ),
                                                          ),
                                                        );
                                                        _hasShownPriceErrorSnackBar =
                                                            true;
                                                      });
                                                      return SizedBox.shrink();
                                                    },
                                                  ),
                                              ],
                                            )
                                          : AnimatedLoadingDots(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction History:',
                            style: TextStyle(
                              color: kmainWhitecolor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'View more',
                            style: TextStyle(
                              color: kmainWhitecolor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 200,
                      width: size.width,
                      decoration: BoxDecoration(
                        color: kmainBackgroundcolor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            blurStyle: BlurStyle.solid,
                            spreadRadius: 0.9,
                            color: kwhitecolor,
                          ),
                        ],
                      ),
                      child: state is FetchUsersLoadingState
                          ? Center(child: AnimatedLoadingDots())
                          : transactions.isEmpty
                          ? Center(
                              child: Text(
                                'No recent transactions yet',
                                style: TextStyle(color: kmainWhitecolor),
                              ),
                            )
                          : ListView.builder(
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final tx = transactions[index];
                                final isSend = tx['type'] == 'send';
                                final amount = tx['amount'] as double? ?? 0.0;
                                final currency = tx['currency'] ?? 'Unknown';
                                final time =
                                    tx['time'] as DateTime? ?? DateTime.now();
                                final formattedTime = DateFormat(
                                  'MMM dd, yyyy - HH:mm',
                                ).format(time);
                                final status = tx['status'] ?? 'Unknown';

                                final amountDisplay = currency == 'BTC'
                                    ? '${amount.toStringAsFixed(8)} BTC'
                                    : amount == 0.0
                                    ? 'Amount unavailable'
                                    : '${NumberFormat("#,##0.00", "en_US").format(amount)} USDT';

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            '${tx['type'].toUpperCase()} $currency Transaction',
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Amount: $amountDisplay'),
                                              Text('Currency: $currency'),
                                              Text(
                                                'Status: $status',
                                                style: TextStyle(
                                                  color: status == 'Confirmed'
                                                      ? Colors.green
                                                      : status == 'Pending'
                                                      ? Colors.yellow
                                                      : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'From: ${tx['from'] ?? 'N/A'}',
                                              ),
                                              Text('To: ${tx['to'] ?? 'N/A'}'),
                                              Text('Time: $formattedTime'),
                                              Text(
                                                'Other Details: ${tx['other_details'] ?? 'N/A'}',
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: customContainer(
                                      60,
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
                                      Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CircleAvatar(
                                              backgroundColor: kmainWhitecolor,
                                              child: Icon(
                                                isSend
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                color: isSend
                                                    ? Colors.red
                                                    : Colors.green,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      amountDisplay,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 10,
                                                            right: 15,
                                                            left: 10
                                                          ),
                                                      child: Text(
                                                        '$status',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              status ==
                                                                  'Confirmed'
                                                              ? Colors.green
                                                              : status ==
                                                                    'Pending'
                                                              ? Colors.yellow
                                                              : Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                      Text('$formattedTime',style: TextStyle(
                                                        color: kmainWhitecolor
                                                      ),)
                                              ],
                                            ),
                                          ),
                                    
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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
