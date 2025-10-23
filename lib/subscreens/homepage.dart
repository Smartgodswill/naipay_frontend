// ignore_for_file: unused_import, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/animations/animatedloader.dart';
import 'package:naipay/options/sendfundsoption.dart';
import 'package:naipay/screens/registerscreen.dart';
import 'package:naipay/state%20management/pricesbloc/prices_bloc.dart';
import 'package:naipay/state%20management/fetchdata/bloc/fetchdata_bloc.dart';
import 'package:naipay/subscreens/learnpage.dart';
import 'package:naipay/subscreens/swap.dart';
import 'package:naipay/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naipay/transactionscreens/recievefundscreen.dart';
import 'package:naipay/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:bdk_flutter/bdk_flutter.dart';

class Homepage extends StatefulWidget {
  final String email;
  Map<String, dynamic>? wallets;
  final Map<String, dynamic>? userInfo;
  List<Map<String, dynamic>>? trc20Transactions;
  final String? address;
  final num? pendingOutgoingBtc;
  final num? pendingOutgoingUsdt;

  Homepage({
    super.key,
    required this.email,
    this.wallets,
    this.userInfo,
    this.trc20Transactions,
    this.address,
    this.pendingOutgoingBtc,
    this.pendingOutgoingUsdt,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with TickerProviderStateMixin {
  bool hasFetchedUserData = false;
  bool hasFetchedPrices = false;
  double _pendingOutgoingBtc = 0.0;
  double _pendingOutgoingUsdt = 0.0;
  bool visble = true;
  bool _hasShownPriceErrorSnackBar = false;
  bool _hasShownUserErrorSnackBar = false;
  bool showAllTransactions = false;

  @override
  void initState() {
    super.initState();
    if (widget.pendingOutgoingBtc != null) {
      _pendingOutgoingBtc = widget.pendingOutgoingBtc!.toDouble();
    }
    if (widget.pendingOutgoingUsdt != null) {
      _pendingOutgoingUsdt = widget.pendingOutgoingUsdt!.toDouble();
    }
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
      fetchDataBloc.add(FetchUserDataEvent(email: widget.email));
      hasFetchedUserData = true;
    }
  }

  void updateAfterTransaction(
    Map<String, dynamic> updatedWalletInfo, {
    required String currency,
  }) {
    print('Updating $currency with: $updatedWalletInfo');
    setState(() {
      if (currency == 'USDT') {
        _pendingOutgoingUsdt = 0.0;
        // Update USDT balance only (no manual transaction history merge)
        final wallet = {...?widget.wallets};
        double usdtBalance = wallet?['usdtBalances'] is int
            ? (wallet['usdtBalances'] as int).toDouble()
            : wallet?['usdtBalances']?.toDouble() ?? 0.0;

        usdtBalance = updatedWalletInfo['newBalance'] != null
            ? double.tryParse(updatedWalletInfo['newBalance'].toString()) ??
                  usdtBalance
            : usdtBalance;

        wallet['usdtBalances'] = usdtBalance;

        widget.wallets = wallet;
        print('Updated USDT balance: $usdtBalance');
      } else if (currency == 'BTC') {
        _pendingOutgoingBtc = 0.0;
        // Update BTC balance (no manual transaction history merge)
        final wallet = {...?widget.wallets};
        int balanceSats = wallet?['balance_sats'] is int
            ? wallet['balance_sats'] as int
            : int.tryParse(wallet['balance_sats']?.toString() ?? '0') ?? 0;

        if (updatedWalletInfo['newBalanceSats'] != null) {
          balanceSats =
              int.tryParse(updatedWalletInfo['newBalanceSats'].toString()) ??
              balanceSats;
        }

        wallet['balance_sats'] = balanceSats;

        widget.wallets = wallet;
        print('Updated BTC wallet: ${widget.wallets}');
      }
    });

    // Trigger a fresh fetch from server/blockchain after update to get latest transaction history
    context.read<FetchdataBloc>().add(FetchUserDataEvent(email: widget.email));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: kmainBackgroundcolor,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: customContainer(
                  200,
                  size.width,
                  BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: kwhitecolor,
                        blurStyle: BlurStyle.outer,
                        blurRadius: 5,
                        spreadRadius: 0.9,
                      ),
                    ],
                    color: kmainBackgroundcolor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 10),
                      Text(
                        'BitSure',
                        style: TextStyle(
                          color: kwhitecolor,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: [
                    ExpansionTile(
                      leading: const Icon(Icons.person, color: Colors.white),
                      title: const Text(
                        "Profile",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white,
                      children: [
                        ListTile(
                          title: Text(
                            overflow: TextOverflow.ellipsis,
                            "Name: ${widget.userInfo?['name']}",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            "Email: ${widget.email}",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.code, color: Colors.white),
                      title: const Text(
                        "Referal Code",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white,
                      children: [
                        ListTile(
                          title: Text(
                            "Your referal code is:",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ListTile(
                          title: Row(
                            children: [
                              Text(
                                "${widget.userInfo?['referralCode']}",
                                style: TextStyle(color: kwhitecolor),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final code =
                                      widget.userInfo?['referralCode'] ?? '';
                                  if (code.isNotEmpty) {
                                    await Clipboard.setData(
                                      ClipboardData(text: code),
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Referral code copied to clipboard!',
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(Icons.copy, color: kwhitecolor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(Icons.numbers, color: Colors.white),
                      title: const Text(
                        "Referal count",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white,
                      children: [
                        ListTile(
                          title: Text(
                            "Your referal count  is:",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            "${widget.userInfo?['referralCount']}",
                            style: TextStyle(color: kwhitecolor),
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      leading: const Icon(
                        Icons.logout_sharp,
                        color: Colors.white,
                      ),
                      title: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white,
                      children: [
                        ListTile(
                          trailing: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return RegisterScreen();
                                  },
                                ),
                              );
                            },
                            icon: Icon(Icons.logout, color: Colors.white70),
                          ),
                          title: Text(
                            "Are you sure you want to loggout?",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      backgroundColor: kmainBackgroundcolor,
      body: BlocConsumer<FetchdataBloc, FetchdataState>(
        listener: (context, state) {
          if (state is FetchUsersFailureState && !_hasShownUserErrorSnackBar) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
            _hasShownUserErrorSnackBar = true;
          }
          if (state is FetchUsersSuccessState) {
            print('Fetched userInfo: ${state.usersInfo}');
            print(
              'Fetched usdt_transaction_history (raw): ${state.usersInfo?['usdt_transaction_history']}',
            );
            setState(() {
              _pendingOutgoingBtc = 0.0;
              _pendingOutgoingUsdt = 0.0;
              if (state.usersInfo?['usdt_transaction_history'] != null) {
                final rawTransactions =
                    state.usersInfo!['usdt_transaction_history']
                        as List<dynamic>;
                widget.trc20Transactions = rawTransactions
                    .whereType<Map<String, dynamic>>()
                    .toList();
                print(
                  'Updated trc20Transactions from userInfo (count: ${widget.trc20Transactions!.length}): $widget.trc20Transactions',
                );
              }
            });
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
          final rawTransactionUsdt =
              userinfo?['usdt_transaction_history'] as List<dynamic>? ??
              widget.trc20Transactions as List<dynamic>?;
          final transactionUsdt = rawTransactionUsdt
              ?.whereType<Map<String, dynamic>>()
              .toList();

          print(
            'Using transactionUsdt (count: ${transactionUsdt?.length ?? 0}): $transactionUsdt',
          );

          double balanceBtc = 0.0;
          double usdtBalance = 0.0;

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

          if (usdtBalance == 0.0 && userinfo != null) {
            usdtBalance = userinfo['usdtBalances'] is int
                ? (userinfo['usdtBalances'] as int).toDouble()
                : userinfo['usdtBalances']?.toDouble() ?? 0.0;
          }

          double displayedBtcBalance = balanceBtc - _pendingOutgoingBtc;
          double displayedUsdtBalance = usdtBalance - _pendingOutgoingUsdt;
          String btcBalanceDisplay =
              '${displayedBtcBalance.toStringAsFixed(8)} BTC';
          String usdtBalanceDisplay =
              '${formatter.format(displayedUsdtBalance)} USDT';

          List<Map<String, dynamic>> transactions = [];

          // Add pending BTC transaction if any (use _pending, not widget.pending)
          if (_pendingOutgoingBtc > 0 && widget.address != null) {
            transactions.add({
              'type': 'send',
              'amount': _pendingOutgoingBtc,
              'currency': 'BTC',
              'time': DateTime.now(),
              'from': wallet?['bitcoin_address'] ?? 'Unknown',
              'to': widget.address,
              'other_details': 'Pending transaction',
              'status': 'Pending',
            });
          }
          // Add pending USDT transaction if any (use _pending, not widget.pending)
          if (_pendingOutgoingUsdt > 0 && widget.address != null) {
            transactions.add({
              'type': 'send',
              'amount': _pendingOutgoingUsdt,
              'currency': 'USDT',
              'time': DateTime.now(),
              'from': wallet?['usdt_address'] ?? 'Unknown',
              'to': widget.address,
              'other_details': 'Pending USDT transaction',
              'status': 'Pending',
            });
          }

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
                  'to': isSend ? widget.address : wallet['bitcoin_address'],
                  'other_details': 'TxID: ${txDetails.txid}',
                  'status': txDetails.confirmationTime != null
                      ? 'Confirmed'
                      : 'Pending',
                };
              }).toList(),
            );
          }

          if (transactionUsdt != null && transactionUsdt.isNotEmpty) {
            print(
              'Processing ${transactionUsdt.length} USDT transactions from userInfo',
            );
            transactions.addAll(
              transactionUsdt.map((tx) {
                final t = tx as Map<String, dynamic>;
                final amount = t['amount'] is int
                    ? (t['amount'] as int).toDouble()
                    : t['amount'] is double
                    ? t['amount'] as double
                    : double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
                return {
                  'type':
                      t['type']?.toString() ??
                      (t['from'] == wallet?['usdt_address']
                          ? 'send'
                          : 'receive'),
                  'amount': amount,
                  'currency': t['currency']?.toString() ?? 'USDT',
                  'time': t['time'] is String
                      ? DateTime.tryParse(t['time']) ?? DateTime.now()
                      : t['time'] is DateTime
                      ? t['time']
                      : DateTime.now(),
                  'from': t['from']?.toString() ?? 'Unknown',
                  'to': t['to']?.toString() ?? 'Unknown',
                  'other_details':
                      t['txId']?.toString() ??
                      t['other_details']?.toString() ??
                      'N/A',
                  'status': t['status']?.toString() ?? 'Pending',
                };
              }).toList(),
            );
          } else {
            print('No USDT transactions found in userInfo');
          }

          transactions.sort((a, b) => b['time'].compareTo(a['time']));
          print(
            'Merged Transactions (count: ${transactions.length}): $transactions',
          );

          return RefreshIndicator(
            onRefresh: () async {
              hasFetchedUserData = false;
              hasFetchedPrices = false;
              _hasShownPriceErrorSnackBar = false;
              _hasShownUserErrorSnackBar = false;

              context.read<FetchdataBloc>().add(
                FetchUserDataEvent(email: userinfo?['email'] ?? widget.email),
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
                          return FetchUsersFailureState(message: 'Timeout');
                        },
                      )
                      .then((state) {
                        if (state is FetchUsersSuccessState) {
                          print(
                            'Fetched usdt_transaction_history on refresh (raw): ${state.usersInfo?['usdt_transaction_history']}',
                          );
                        } else if (state is FetchUsersFailureState) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fetch failed: ${state.message}'),
                            ),
                          );
                        }
                      })
                      .timeout(
                        const Duration(seconds: 5),
                        onTimeout: () {
                          print('FetchdataBloc timeout');
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
                          return PricesErrorState('Timeout');
                        },
                      )
                      .then((state) {
                        if (state is PricesErrorState) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Price fetch failed: ${state.message}',
                              ),
                            ),
                          );
                        }
                      })
                      .timeout(
                        const Duration(seconds: 5),
                        onTimeout: () {
                          print('PricesBloc timeout');
                        },
                      ),
                ]);
                print('Refresh completed: ${DateTime.now()}');
              } catch (e) {
                print('Refresh error: $e');
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
                    customContainer(
                      39,
                      size.width,
                      BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      Row(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: IconButton(
                                  onPressed: () {
                                    _scaffoldKey.currentState?.openDrawer();
                                  },
                                  icon: Icon(
                                    Icons.menu,
                                    color: kwhitecolor,
                                    size: 25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  userinfo != null ? 'Welcome!' : 'Welcome!',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: kwhitecolor,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 0, left: 50),
                      child: Text(
                        userinfo != null ? '${userinfo['name']}' : '.........',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kmainWhitecolor,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 150,
                          child: customContainer(
                            250,
                            330,
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
                                topRight: Radius.circular(20),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Column(
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
                                                color: kwhitecolor,
                                              )
                                            : Icon(
                                                Icons.visibility_off,
                                                color: kmainWhitecolor,
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
                                          top: 11,
                                        ),
                                        child: Text(
                                          'Bitcoin Balance:',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: kmainWhitecolor,
                                          ),
                                        ),
                                      ),
                                      if (state is FetchUsersLoadingState &&
                                          widget.wallets == null)
                                        Padding(
                                          padding: const EdgeInsets.all(2.0),
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
                                                      displayedBtcBalance *
                                                      btcPriceInUsdt;
                                                  usdtBalanceDisplay = Text(
                                                    displayedBtcBalance == 0.0
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
                                                      .addPostFrameCallback((
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
                                                          color:
                                                              kmainWhitecolor,
                                                        ),
                                                        textAlign:
                                                            TextAlign.end,
                                                      ),
                                                    ),
                                                    visble
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 20,
                                                                ),
                                                            child:
                                                                usdtBalanceDisplay,
                                                          )
                                                        : Text(
                                                            '*********',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  kwhitecolor,
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
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: customContainer(
                        size.height / 16,
                        330,
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
                            bottomLeft: Radius.circular(20),
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
                                if (state is FetchUsersLoadingState &&
                                    widget.wallets == null)
                                  AnimatedLoadingDots()
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 25),
                                    child: visble
                                        ? Text(
                                            "${formatter.format(displayedUsdtBalance)} USDT",
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
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      child: SizedBox(
                        width: 400,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                        PageRouteBuilder(
                                          transitionDuration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => Learnpage(),
                                          transitionsBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                const curve =
                                                    Curves.easeOutBack;
                                                final scaleTween =
                                                    Tween<double>(
                                                      begin: 0.8,
                                                      end: 1.0,
                                                    ).chain(
                                                      CurveTween(curve: curve),
                                                    );
                                                final fadeTween = Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                );
                                                return FadeTransition(
                                                  opacity: animation.drive(
                                                    fadeTween,
                                                  ),
                                                  child: ScaleTransition(
                                                    scale: animation.drive(
                                                      scaleTween,
                                                    ),
                                                    child: child,
                                                  ),
                                                );
                                              },
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
                                  InkWell(
                                    onTap: () {
                                      /*  Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          transitionDuration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => SwapPage(
                                                initialcoin: "BTC",
                                                btcbalance: displayedBtcBalance,
                                                usdtbalance:
                                                    displayedUsdtBalance,
                                                userEmail:
                                                    widget.userInfo?['email'],
                                                userinfo: widget.userInfo ?? {},
                                              ),
                                          transitionsBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                const beginOffset = Offset(
                                                  1.0,
                                                  0.0,
                                                );
                                                const endOffset = Offset.zero;
                                                const curve = Curves.easeInOut;
                                                final offsetTween =
                                                    Tween(
                                                      begin: beginOffset,
                                                      end: endOffset,
                                                    ).chain(
                                                      CurveTween(curve: curve),
                                                    );
                                                final fadeTween = Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                );
                                                return SlideTransition(
                                                  position: animation.drive(
                                                    offsetTween,
                                                  ),
                                                  child: FadeTransition(
                                                    opacity: animation.drive(
                                                      fadeTween,
                                                    ),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                        ),
                                      );*/
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            backgroundColor: ktransparentcolor,
                                            content: customContainer(
                                              230,
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.7,
                                              BoxDecoration(
                                                color: kmainBackgroundcolor,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  TweenAnimationBuilder<double>(
                                                    tween: Tween(
                                                      begin: 0,
                                                      end: 10,
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 1,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                    builder:
                                                        (
                                                          context,
                                                          value,
                                                          child,
                                                        ) {
                                                          return Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  bottom: value,
                                                                ),
                                                            child: const Text(
                                                              "🛠️",
                                                              style: TextStyle(
                                                                fontSize: 42,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                    onEnd: () {},
                                                  ),

                                                  const SizedBox(height: 10),

                                                  Text(
                                                    "Swap is down for maintenance",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: kmainWhitecolor,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 8),

                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8.0,
                                                        ),
                                                    child: Text(
                                                      "We're working on improvements and upgrades.\nPlease check back soon!",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: kmainWhitecolor
                                                            .withOpacity(0.9),
                                                        fontSize: 14,
                                                        height: 1.4,
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
                                    child: CircleAvatar(
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
                                    onTap: () async {
                                      final result = await showDialog(
                                        context: context,
                                        builder: (context) => sendfundsoption(
                                          context,
                                          userinfo ?? {},
                                          wallet,
                                          balanceBtc,
                                          usdtBalance,
                                          widget.email,
                                        ),
                                      );
                                      if (result != null &&
                                          result is Map<String, dynamic>) {
                                        final currency =
                                            result['currency']?.toString() ??
                                            'USDT';
                                        updateAfterTransaction(
                                          result,
                                          currency: currency,
                                        );
                                      }
                                    },
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: ksubcolor,
                                      child: Center(
                                        child: Icon(
                                          Icons.arrow_upward,
                                          color: kwhitecolor,
                                          size: 30,
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
                                      ).then((result) {
                                        if (result != null &&
                                            result is bool &&
                                            result) {
                                          context.read<FetchdataBloc>().add(
                                            FetchUserDataEvent(
                                              email: widget.email,
                                            ),
                                          );
                                        }
                                      });
                                    },
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: ksubcolor,
                                      child: Center(
                                        child: Icon(
                                          Icons.arrow_downward,
                                          color: kwhitecolor,
                                          size: 30,
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
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showAllTransactions = !showAllTransactions;
                              });
                            },
                            child: Text(
                              showAllTransactions ? 'View less' : 'View more',
                              style: TextStyle(
                                color: kmainWhitecolor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: showAllTransactions
                          ? 400
                          : 120, // expands height when viewing more
                      width: size.width,
                      decoration: BoxDecoration(
                        color: kmainBackgroundcolor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            blurStyle: BlurStyle.outer,
                            spreadRadius: 0.9,
                            color: kwhitecolor,
                          ),
                        ],
                      ),
                      child:
                          state is FetchUsersLoadingState &&
                              widget.wallets == null &&
                              transactionUsdt == null
                          ? Center(child: AnimatedLoadingDots())
                          : transactions.isEmpty
                          ? Center(
                              child: Text(
                                'No recent transactions yet',
                                style: TextStyle(color: kmainWhitecolor),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: showAllTransactions
                                  ? transactions.length
                                  : (transactions.length > 3
                                        ? 3
                                        : transactions.length),
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
                                    : currency == 'USDT'
                                    ? '${formatter.format(amount)} $currency'
                                    : amount == 0.0
                                    ? 'Amount unavailable'
                                    : '${formatter.format(amount)} $currency';

                                return Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: kmainBackgroundcolor,
                                          title: Text(
                                            '${tx['type'].toUpperCase()} $currency Transaction',
                                            style: TextStyle(
                                              color: kmainWhitecolor,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Amount: $amountDisplay',
                                                style: TextStyle(
                                                  color: kmainWhitecolor,
                                                ),
                                              ),
                                              Text(
                                                'Currency: $currency',
                                                style: TextStyle(
                                                  color: kmainWhitecolor,
                                                ),
                                              ),
                                              Text(
                                                'Status: $status',
                                                style: TextStyle(
                                                  color: kwhitecolor
                                                ),
                                              ),
                                              Text(
                                                'From: ${tx['from'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: kmainWhitecolor,
                                                ),
                                              ),
                                              Text(
                                                'To: ${tx['to'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: kmainWhitecolor,
                                                ),
                                              ),
                                              Text(
                                                'Time: $formattedTime',
                                                style: TextStyle(
                                                  color: kmainWhitecolor,
                                                ),
                                              ),
                                              Text(
                                                'Other Details: ${tx['other_details'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  color: kmainWhitecolor,
                                                ),
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
                                        color: const Color.fromARGB(
                                          255,
                                          11,
                                          6,
                                          47,
                                        ),
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
                                                            left: 10,
                                                          ),
                                                      child: Text(
                                                        status.toLowerCase(),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:kwhitecolor
                                                              
                                                              
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '$formattedTime',
                                                  style: TextStyle(
                                                    color: kmainWhitecolor,
                                                  ),
                                                ),
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