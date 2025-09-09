// ignore_for_file: use_build_context_synchronously
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
import 'package:naipay/transactionscreens/settransactipnpinscreen.dart';
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

  /// Update USDT balance + TRC20 transactions after a transaction
  void updateUsdtAfterTransaction(Map<String, dynamic> updatedWalletInfo) {
    print('Updating USDT with: $updatedWalletInfo');
    setState(() {
      _pendingOutgoingUsdt = 0.0;

      // Update USDT balance
      final wallet = {...?widget.wallets};
      double usdtBalance = wallet?['usdtBalances'] is int
          ? (wallet['usdtBalances'] as int).toDouble()
          : wallet?['usdtBalances']?.toDouble() ?? 0.0;

      usdtBalance = updatedWalletInfo['newBalance'] != null
          ? double.tryParse(updatedWalletInfo['newBalance'].toString()) ?? usdtBalance
          : usdtBalance;

      wallet['usdtBalances'] = usdtBalance;

      // Merge TRC20 transactions from userInfo
      final newTransactions = updatedWalletInfo['trc20Transactions'] as List<dynamic>? ?? [];
      final oldTransactions = widget.userInfo?['usdt_transaction_history'] as List<dynamic>? ?? [];
      final mergedTransactions = [...newTransactions, ...oldTransactions]
          .whereType<Map<String, dynamic>>()
          .toList();

      widget.wallets = wallet;
      widget.trc20Transactions = mergedTransactions;
      print('Merged TRC20 Transactions (count: ${widget.trc20Transactions!.length}): ${widget.trc20Transactions}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final formatter = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: kmainBackgroundcolor,
      body: BlocConsumer<FetchdataBloc, FetchdataState>(
        listener: (context, state) {
          if (state is FetchUsersFailureState && !_hasShownUserErrorSnackBar) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
            _hasShownUserErrorSnackBar = true;
          }
          if (state is FetchUsersSuccessState) {
            print('Fetched userInfo: ${state.usersInfo}');
            print('Fetched usdt_transaction_history (raw): ${state.usersInfo?['usdt_transaction_history']}');
            setState(() {
              _pendingOutgoingBtc = 0.0;
              _pendingOutgoingUsdt = 0.0;
              // Safely update trc20Transactions from userInfo
              if (state.usersInfo?['usdt_transaction_history'] != null) {
                final rawTransactions = state.usersInfo!['usdt_transaction_history'] as List<dynamic>;
                widget.trc20Transactions = rawTransactions
                    .whereType<Map<String, dynamic>>()
                    .toList();
                print('Updated trc20Transactions from userInfo (count: ${widget.trc20Transactions!.length}): $widget.trc20Transactions');
              }
            });
          }
        },
        builder: (context, state) {
          final wallet = (state is FetchUsersSuccessState && state.walletdata != null)
              ? state.walletdata
              : widget.wallets;
          final userinfo = (state is FetchUsersSuccessState && state.usersInfo != null)
              ? state.usersInfo
              : widget.userInfo;
          // Safely handle transactionUsdt with type checking
          final rawTransactionUsdt = userinfo?['usdt_transaction_history'] as List<dynamic>? ??
              widget.trc20Transactions as List<dynamic>?;
          final transactionUsdt = rawTransactionUsdt?.whereType<Map<String, dynamic>>().toList();

          print('Using transactionUsdt (count: ${transactionUsdt?.length ?? 0}): $transactionUsdt');

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
          String btcBalanceDisplay = '${displayedBtcBalance.toStringAsFixed(8)} BTC';
          String usdtBalanceDisplay = '${formatter.format(displayedUsdtBalance)} USDT';

          List<Map<String, dynamic>> transactions = [];

          // Add pending BTC transaction if any
          if (widget.pendingOutgoingBtc != null && widget.pendingOutgoingBtc! > 0 && widget.address != null) {
            transactions.add({
              'type': 'send',
              'amount': widget.pendingOutgoingBtc!.toDouble(),
              'currency': 'BTC',
              'time': DateTime.now(),
              'from': wallet?['bitcoin_address'] ?? 'Unknown',
              'to': widget.address,
              'other_details': 'Pending transaction',
              'status': 'Pending',
            });
          }

          // Add pending USDT transaction if any
          if (widget.pendingOutgoingUsdt != null && widget.pendingOutgoingUsdt! > 0 && widget.address != null) {
            transactions.add({
              'type': 'send',
              'amount': widget.pendingOutgoingUsdt!.toDouble(),
              'currency': 'USDT',
              'time': DateTime.now(),
              'from': wallet?['usdt_address'] ?? 'Unknown',
              'to': widget.address,
              'other_details': 'Pending USDT transaction',
              'status': 'Pending',
            });
          }

          // BTC transactions from wallet
          if (wallet?['transaction_history'] != null) {
            transactions.addAll(
              (wallet!['transaction_history'] as List<dynamic>).map((tx) {
                final txDetails = tx as TransactionDetails;
                final isSend = txDetails.sent > 0;
                final amountSats = isSend ? txDetails.sent - txDetails.received : txDetails.received;
                final amountBtc = amountSats / 100000000;
                return {
                  'type': isSend ? 'send' : 'receive',
                  'amount': amountBtc,
                  'currency': 'BTC',
                  'time': txDetails.confirmationTime?.timestamp != null
                      ? DateTime.fromMillisecondsSinceEpoch(txDetails.confirmationTime!.timestamp * 1000)
                      : DateTime.now(),
                  'from': isSend ? wallet['bitcoin_address'] : 'Unknown',
                  'to': isSend ? widget.address : wallet['bitcoin_address'],
                  'other_details': 'TxID: ${txDetails.txid}',
                  'status': txDetails.confirmationTime != null ? 'Confirmed' : 'Pending',
                };
              }).toList(),
            );
          }

          // USDT transactions from userInfo (only total amount, no fee breakdown)
          if (transactionUsdt != null && transactionUsdt.isNotEmpty) {
            print('Processing ${transactionUsdt.length} USDT transactions from userInfo');
            transactions.addAll(
              transactionUsdt.map((tx) {
                final t = tx as Map<String, dynamic>;
                final amount = t['amount'] is int
                    ? (t['amount'] as int).toDouble()
                    : t['amount'] is double
                        ? t['amount'] as double
                        : double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
                return {
                  'type': t['type']?.toString() ?? (t['from'] == wallet?['usdt_address'] ? 'send' : 'receive'),
                  'amount': amount, // Only the base amount, no fee separation
                  'currency': t['currency']?.toString() ?? 'USDT',
                  'time': t['time'] is String
                      ? DateTime.tryParse(t['time']) ?? DateTime.now()
                      : t['time'] is DateTime
                          ? t['time']
                          : DateTime.now(),
                  'from': t['from']?.toString() ?? 'Unknown',
                  'to': t['to']?.toString() ?? 'Unknown',
                  'other_details': t['txId']?.toString() ?? t['other_details']?.toString() ?? 'N/A',
                  'status': t['status']?.toString() ?? 'Pending', // Updated status handling
                };
              }).toList(),
            );
          } else {
            print('No USDT transactions found in userInfo');
          }

          // Sort transactions newest first
          transactions.sort((a, b) => b['time'].compareTo(a['time']));
          print('Merged Transactions (count: ${transactions.length}): $transactions');

          return RefreshIndicator(
            onRefresh: () async {
              hasFetchedUserData = false;
              hasFetchedPrices = false;
              _hasShownPriceErrorSnackBar = false;
              _hasShownUserErrorSnackBar = false;

              context.read<FetchdataBloc>().add(FetchUserDataEvent(email: userinfo?['email'] ?? widget.email));
              context.read<PricesBloc>().add(FetchPricesEvent());

              try {
                print('Starting refresh: ${DateTime.now()}');
                await Future.wait([
                  context.read<FetchdataBloc>().stream.firstWhere(
                        (state) => state is FetchUsersSuccessState || state is FetchUsersFailureState,
                        orElse: () {
                          print('FetchdataBloc timeout');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('User data fetch timed out')),
                          );
                          return FetchUsersFailureState(message: 'Timeout');
                        },
                      ).then((state) {
                        if (state is FetchUsersSuccessState) {
                          print('Fetched usdt_transaction_history on refresh (raw): ${state.usersInfo?['usdt_transaction_history']}');
                        } else if (state is FetchUsersFailureState) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fetch failed: ${state.message}')),
                          );
                        }
                      }).timeout(
                        const Duration(seconds: 5),
                        onTimeout: () {
                          print('FetchdataBloc timeout');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('User data fetch timed out')),
                          );
                        },
                      ),
                  context.read<PricesBloc>().stream.firstWhere(
                        (state) => state is PricesLoadedSuccessState || state is PricesErrorState,
                        orElse: () {
                          print('PricesBloc timeout');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Price fetch timed out')),
                          );
                          return PricesErrorState('Timeout');
                        },
                      ).then((state) {
                        if (state is PricesErrorState) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Price fetch failed: ${state.message}')),
                          );
                        }
                      }).timeout(
                        const Duration(seconds: 5),
                        onTimeout: () {
                          print('PricesBloc timeout');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Price fetch timed out')),
                          );
                        },
                      ),
                ]);
                print('Refresh completed: ${DateTime.now()}');
              } catch (e) {
                print('Refresh error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Refresh failed: $e')),
                );
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 45),
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
                                    userinfo != null ? 'Hi, ${userinfo['name']}' : 'Hi, .......',
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
                        SizedBox(
                          height: 147,
                          child: customContainer(
                            size.height / 5.3,
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
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
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
                                          ? Icon(Icons.visibility, color: ksubbackgroundcolor)
                                          : Icon(Icons.visibility_off, color: ksubbackgroundcolor),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12, top: 11),
                                      child: Text(
                                        'Bitcoin Balance:',
                                        style: TextStyle(fontSize: 15, color: kmainWhitecolor),
                                      ),
                                    ),
                                    if (state is FetchUsersLoadingState && widget.wallets == null)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: AnimatedLoadingDots(),
                                      )
                                    else if (wallet != null)
                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 28, right: 12),
                                          child: BlocBuilder<PricesBloc, PricesState>(
                                            builder: (context, priceState) {
                                              double btcPriceInUsdt = 0.0;
                                              Widget usdtBalanceDisplay = AnimatedLoadingDots();

                                              if (priceState is PricesLoadedSuccessState) {
                                                btcPriceInUsdt =
                                                    priceState.prices['BTC']?['price']?.toDouble() ?? 0.0;
                                                double usdtEquivalent = displayedBtcBalance * btcPriceInUsdt;
                                                usdtBalanceDisplay = Text(
                                                  displayedBtcBalance == 0.0
                                                      ? '0.00 USDT'
                                                      : '${formatter.format(usdtEquivalent)} USDT',
                                                  style: TextStyle(fontSize: 10, color: kwhitecolor),
                                                  textAlign: TextAlign.end,
                                                );
                                              } else if (priceState is PricesLoadingState) {
                                                usdtBalanceDisplay = AnimatedLoadingDots();
                                              } else if (priceState is PricesErrorState &&
                                                  !_hasShownPriceErrorSnackBar) {
                                                usdtBalanceDisplay = Text(
                                                  'Price unavailable',
                                                  style: TextStyle(fontSize: 10, color: kwhitecolor),
                                                  textAlign: TextAlign.end,
                                                );
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        priceState.message.contains('429')
                                                            ? 'Rate limit exceeded. Please try again later.'
                                                            : 'Failed to load prices: ${priceState.message}',
                                                      ),
                                                    ),
                                                  );
                                                  _hasShownPriceErrorSnackBar = true;
                                                });
                                              }

                                              return Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  SizedBox(
                                                    width: 250,
                                                    child: Text(
                                                      visble ? btcBalanceDisplay : '*********',
                                                      style: TextStyle(fontSize: 20, color: kmainWhitecolor),
                                                      textAlign: TextAlign.end,
                                                    ),
                                                  ),
                                                  visble
                                                      ? Padding(
                                                          padding: const EdgeInsets.only(bottom: 20),
                                                          child: usdtBalanceDisplay,
                                                        )
                                                      : Text(
                                                          '*********',
                                                          style: TextStyle(fontSize: 10, color: kwhitecolor),
                                                          textAlign: TextAlign.end,
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
                                        style: TextStyle(fontSize: 50, color: kwhitecolor),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: customContainer(
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
                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
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
                                    style: TextStyle(fontSize: 15, color: kmainWhitecolor),
                                  ),
                                ),
                                if (state is FetchUsersLoadingState && widget.wallets == null)
                                  AnimatedLoadingDots()
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 25),
                                    child: visble
                                        ? Text(
                                            "${formatter.format(displayedUsdtBalance)} USDT",
                                            style: TextStyle(fontSize: 20, color: kmainWhitecolor),
                                          )
                                        : Text(
                                            '********',
                                            style: TextStyle(color: kmainWhitecolor),
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
                                        MaterialPageRoute(builder: (context) => Learnpage()),
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
                                      print('USDT transactions from userInfo: ${widget.userInfo?['usdt_transaction_history']}');
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
                                      print('Send button tapped');
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
                                      if (result != null && result is Map<String, dynamic>) {
                                        updateUsdtAfterTransaction(result);
                                      }
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
                                          builder: (context) => Recievefundscreen(
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          padding: const EdgeInsets.only(left: 1, top: 4),
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
                                      padding: const EdgeInsets.only(right: 8, top: 20),
                                      child: priceState is PricesLoadedSuccessState
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
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
                                                        color: (priceState.prices['BTC']?['change_24h'] ?? 0.0) >= 0
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Icon(
                                                      (priceState.prices['BTC']?['change_24h'] ?? 0.0) >= 0
                                                          ? Icons.arrow_upward
                                                          : Icons.arrow_downward,
                                                      color: (priceState.prices['BTC']?['change_24h'] ?? 0.0) >= 0
                                                          ? Colors.green
                                                          : Colors.red,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'Rank: ${priceState.prices['BTC']?['rank'] ?? 'N/A'}',
                                                  style: TextStyle(color: kmainWhitecolor, fontSize: 12),
                                                ),
                                              ],
                                            )
                                          : priceState is PricesErrorState
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      'Error: Price unavailable',
                                                      style: TextStyle(color: Colors.red, fontSize: 14),
                                                    ),
                                                    if (!_hasShownPriceErrorSnackBar)
                                                      Builder(
                                                        builder: (context) {
                                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  priceState.message.contains('429')
                                                                      ? 'Rate limit exceeded. Please try again later.'
                                                                      : 'Failed to load prices: ${priceState.message}',
                                                                ),
                                                              ),
                                                            );
                                                            _hasShownPriceErrorSnackBar = true;
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      padding: const EdgeInsets.only(right: 8, top: 20),
                                      child: priceState is PricesLoadedSuccessState
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
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
                                                        color: (priceState.prices['USDT']?['change_24h'] ?? 0.0) >= 0
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Icon(
                                                      (priceState.prices['USDT']?['change_24h'] ?? 0.0) >= 0
                                                          ? Icons.arrow_upward
                                                          : Icons.arrow_downward,
                                                      color: (priceState.prices['USDT']?['change_24h'] ?? 0.0) >= 0
                                                          ? Colors.green
                                                          : Colors.red,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'Rank: ${priceState.prices['USDT']?['rank'] ?? 'N/A'}',
                                                  style: TextStyle(color: kmainWhitecolor, fontSize: 12),
                                                ),
                                              ],
                                            )
                                          : priceState is PricesErrorState
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      'Error: Price unavailable',
                                                      style: TextStyle(color: Colors.red, fontSize: 14),
                                                    ),
                                                    if (!_hasShownPriceErrorSnackBar)
                                                      Builder(
                                                        builder: (context) {
                                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  priceState.message.contains('429')
                                                                      ? 'Rate limit exceeded. Please try again later.'
                                                                      : 'Failed to load prices: ${priceState.message}',
                                                                ),
                                                              ),
                                                            );
                                                            _hasShownPriceErrorSnackBar = true;
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
                            style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'View more',
                            style: TextStyle(color: kmainWhitecolor, fontWeight: FontWeight.w600),
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
                      child: state is FetchUsersLoadingState && widget.wallets == null && transactionUsdt == null
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
                                  itemCount: transactions.length,
                                  itemBuilder: (context, index) {
                                    final tx = transactions[index];
                                    final isSend = tx['type'] == 'send';
                                    final amount = tx['amount'] as double? ?? 0.0;
                                    final currency = tx['currency'] ?? 'Unknown';
                                    final time = tx['time'] as DateTime? ?? DateTime.now();
                                    final formattedTime = DateFormat('MMM dd, yyyy - HH:mm').format(time);
                                    final status = tx['status'] ?? 'Unknown';

                                    // Display only the total amount for USDT (no fee breakdown)
                                    final amountDisplay = currency == 'BTC'
                                        ? '${amount.toStringAsFixed(8)} BTC'
                                        : currency == 'USDT'
                                            ? '${formatter.format(amount)} $currency' // Only base amount for USDT
                                            : amount == 0.0
                                                ? 'Amount unavailable'
                                                : '${formatter.format(amount)} $currency';

                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('${tx['type'].toUpperCase()} $currency Transaction'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  Text('From: ${tx['from'] ?? 'N/A'}'),
                                                  Text('To: ${tx['to'] ?? 'N/A'}'),
                                                  Text('Time: $formattedTime'),
                                                  Text('Other Details: ${tx['other_details'] ?? 'N/A'}'),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
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
                                                    isSend ? Icons.arrow_upward : Icons.arrow_downward,
                                                    color: isSend ? Colors.red : Colors.green,
                                                    size: 30,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          amountDisplay,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 10, right: 15, left: 10),
                                                          child: Text(
                                                            '$status',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: status == 'Confirmed'
                                                                  ? Colors.green
                                                                  : status == 'Pending'
                                                                      ? Colors.yellow
                                                                      : Colors.red,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      '$formattedTime',
                                                      style: TextStyle(color: kmainWhitecolor),
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