import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:naipay/state%20management/swap/bloc/sendswaptobitnob_bloc.dart';
import 'package:naipay/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:naipay/utils/utils.dart';

class SwapPage extends StatefulWidget {
  final String initialcoin;
  final double btcbalance;
  final double usdtbalance;
  final String userEmail;
  final Map<String, dynamic> userinfo;
  const SwapPage({
    super.key,
    required this.initialcoin,
    required this.btcbalance,
    required this.usdtbalance,
    required this.userEmail,
    required this.userinfo,
  });

  @override
  State<SwapPage> createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  late String selectedFromCurrency;
  late String selectedToCurrency;
  final btcFormatter = NumberFormat('#,##0.00000000', 'en_US');
  final usdtFormatter = NumberFormat('#,##0.00', 'en_US');
  final TextEditingController _fromAmountController = TextEditingController();
  final TextEditingController _toAmountController = TextEditingController();
  bool _isFromInputValid = true;
  String? _fromErrorMessage;
  Timer? _debounceTimer;
  Timer? _btcPriceTimer;
  bool _isLoadingQuote = false;
  Map<String, dynamic>? _quoteData;

  final String _backendQuoteUrl =
      'http://10.0.2.2:2000/auth/initialize-swap-quote';
  final String _backendOrderUrl =
      'http://10.0.2.2:2000/auth/create-swap-order';

  double? _btcPriceUsd;
  late SendswaptobitnobBloc _swapBloc;


  Future<void> _callProceedSwap(String txid,  String usdtAddress) async {
  try {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:2000/auth/proceed-swap"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "txid": txid,
        "usdtAddress": usdtAddress, 
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["success"] == true && data["status"] == "payout_sent") {
        _showSuccessMessage("USDT sent! TXID: ${data['payoutTxId']}");
      } else {
        _showError("Waiting for BTC confirmation...");
      }
    } else {
      _showError("Server error: ${response.body}");
    }
  } catch (e) {
    _showError("Failed to call backend: $e");
  }
}

void _showSuccessMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.green),
  );
}

  @override
  void initState() {
    super.initState();
    selectedFromCurrency =
        widget.initialcoin == 'BTC' || widget.initialcoin == 'USDT'
        ? widget.initialcoin
        : 'BTC';
    selectedToCurrency = selectedFromCurrency == 'BTC' ? 'USDT' : 'BTC';
    _fromAmountController.addListener(_debouncedValidateAndFetchQuote);

    _fetchBtcPrice();
    _btcPriceTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchBtcPrice();
    });
    _swapBloc = SendswaptobitnobBloc();
  }

  @override
  void dispose() {
    _fromAmountController.removeListener(_debouncedValidateAndFetchQuote);
    _debounceTimer?.cancel();
    _btcPriceTimer?.cancel();
    _fromAmountController.dispose();
    _toAmountController.dispose();
    _swapBloc.close();
    super.dispose();
  }

  Future<void> _fetchBtcPrice() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd",
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _btcPriceUsd = data["bitcoin"]["usd"]?.toDouble();
        });
      }
    } catch (e) {
      debugPrint("Error fetching BTC price: $e");
    }
  }

  void _debouncedValidateAndFetchQuote() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _validateFromInput();
      if (_isFromInputValid && _fromAmountController.text.isNotEmpty) {
        _fetchQuote();
      }
    });
  }

  void _validateFromInput() {
    final input = _fromAmountController.text;
    final balance = selectedFromCurrency == 'BTC'
        ? widget.btcbalance
        : widget.usdtbalance;

    setState(() {
      if (input.isEmpty) {
        _isFromInputValid = true;
        _fromErrorMessage = null;
        _toAmountController.text = '0';
        _quoteData = null;
        return;
      }

      final amount = double.tryParse(input);
      if (amount == null) {
        _isFromInputValid = false;
        _fromErrorMessage = 'Please enter a valid number';
        _toAmountController.text = '0';
        _quoteData = null;
      } else if (amount <= 0) {
        _isFromInputValid = false;
        _fromErrorMessage = 'Amount must be greater than 0';
        _toAmountController.text = '0';
        _quoteData = null;
      } else if (amount > balance) {
        _isFromInputValid = false;
        _fromErrorMessage = 'Amount exceeds available balance';
        _toAmountController.text = '0';
        _quoteData = null;
      } else {
        _isFromInputValid = true;
        _fromErrorMessage = null;
      }
    });
  }

  Future<void> _fetchQuote() async {
    setState(() => _isLoadingQuote = true);
    try {
      final inputAmount = double.parse(_fromAmountController.text);

      // ✅ Send raw amount to backend for quote (let backend convert to USD)
      final amountToSend = inputAmount;

      final response = await http.post(
        Uri.parse(_backendQuoteUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromCurrency': selectedFromCurrency.toLowerCase(),
          'toCurrency': selectedToCurrency.toLowerCase(),
          'amount': amountToSend, // ✅ Always send in original currency
          'email': widget.userEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final toAmount = data['toAmount']?.toDouble() ?? 0.0;
        setState(() {
          _quoteData = data;
          _toAmountController.text = selectedToCurrency == 'BTC'
              ? btcFormatter.format(toAmount)
              : usdtFormatter.format(toAmount);
        });
      } else {
        _showError('Failed to fetch price: ${response.body}');
        setState(() {
          _toAmountController.text = '0';
          _quoteData = null;
        });
      }
    } catch (e) {
      _showError('Error fetching quote: $e');
      setState(() {
        _toAmountController.text = '0';
        _quoteData = null;
      });
    } finally {
      setState(() => _isLoadingQuote = false);
    }
  }

  Future<void> _createSwapOrder() async {
    if (_quoteData == null) {
      _showError("Please get a quote first.");
      return;
    }

    try {
      final inputAmount = double.parse(_fromAmountController.text);

      double amountToSend;
      if (selectedFromCurrency == 'BTC' && selectedToCurrency == 'USDT') {
        // ✅ Convert BTC to USD before sending
        if (_btcPriceUsd == null) {
          _showError("Unable to fetch BTC price. Try again.");
          return;
        }
        amountToSend = inputAmount * _btcPriceUsd!;
      } else {
        amountToSend = inputAmount;
      }

      final response = await http.post(
        Uri.parse(_backendOrderUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromCurrency': selectedFromCurrency.toLowerCase(),
          'toCurrency': selectedToCurrency.toLowerCase(),
          'amount': amountToSend, // ✅ Now USD if BTC→USDT
          'email': widget.userEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showOrderDetails(data);
      } else {
        _showError('Failed to create order: ${response.body}');
        print("🔍 Failed to create order: ${response.body}");
      }
    } catch (e) {
      _showError('Error creating order: $e');
    }
  }

  void _showOrderDetails(Map<String, dynamic> orderData) {
    final order = orderData['order'] ?? {};
    final depositAddress = order['depositAddress'] ?? "N/A";
    final depositAmount = order['depositAmount']?.toString() ?? "0";
    final receiveAmount = order['receiveAmount']?.toString() ?? "0";
    final depositCurrency = order['depositCurrency'] ?? selectedFromCurrency;
    final receiveCurrency = order['receiveCurrency'] ?? selectedToCurrency;
    final rate = order['rate']?.toString() ?? "N/A";
    final fees = order['fees']?.toString() ?? "0";
    final expiration = order['expiration'];

    // Parse expiration time if available
    DateTime? expirationTime;
    if (expiration != null) {
      try {
        expirationTime = DateTime.parse(expiration);
      } catch (e) {
        debugPrint("Error parsing expiration: $e");
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: kmainBackgroundcolor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kwhitecolor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                "Swap Order Details",
                style: TextStyle(
                  color: kmainWhitecolor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Swap Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kwhitecolor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kwhitecolor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You Send",
                              style: TextStyle(
                                color: kwhitecolor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "$depositAmount $depositCurrency",
                              style: TextStyle(
                                color: kmainWhitecolor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.greenAccent,
                          size: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "You Receive",
                              style: TextStyle(
                                color: kwhitecolor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "$receiveAmount $receiveCurrency",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (rate != "N/A") ...[
                      const SizedBox(height: 12),
                      Divider(color: kwhitecolor.withOpacity(0.2)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Rate: 1 $depositCurrency ≈ $rate $receiveCurrency",
                            style: TextStyle(
                              color: kwhitecolor.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Deposit Address Section
              Text(
                "Send $depositCurrency to this address:",
                style: TextStyle(
                  color: kmainWhitecolor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        depositAddress,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Copy to clipboard functionality
                        // You can implement this using clipboard package
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Address copied to clipboard"),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.copy,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Additional Information
              if (fees != "0") ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Network Fee:",
                      style: TextStyle(color: kwhitecolor.withOpacity(0.7)),
                    ),
                    Text(
                      "$fees $depositCurrency",
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              if (expirationTime != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Quote Expires:",
                      style: TextStyle(color: kwhitecolor.withOpacity(0.7)),
                    ),
                    Text(
                      "${expirationTime.hour.toString().padLeft(2, '0')}:${expirationTime.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Warning Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Send exactly $depositAmount $depositCurrency to the address above. Sending a different amount may result in loss of funds.",
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kwhitecolor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: kwhitecolor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        bool isSending =
                            false; // local state for loading indicator

                        return ElevatedButton(
                          onPressed: isSending
                              ? null // disable button while sending
                              : () {
                                  setState(() => isSending = true);

                                  final depositAddress =
                                      order['depositAddress'] ?? '';

                                  // Safely parse depositAmount
                                  final depositAmountRaw =
                                      order['depositAmount'] ?? 0.0;
                                  final depositAmount =
                                      depositAmountRaw is String
                                      ? double.tryParse(depositAmountRaw) ?? 0.0
                                      : depositAmountRaw as double;
                                  String mnemonic =
                                      widget.userinfo['mnemonic'] ?? '';
                                  print(
                                    "💡 data send to bitnob is ${depositAmount},${depositAddress}",
                                  );
                                  _swapBloc.add(
                                    SendBtcToBitnobEvent(
                                      userMnemonic:
                                          mnemonic, // replace with actual
                                      depositAddress: depositAddress,
                                      btcAmount: depositAmount,
                                      fromCurrency: selectedFromCurrency,
                                      toCurrency: selectedToCurrency,
                                    ),
                                  );
                                  StreamSubscription?
                                  subscription; // declare nullable variable first

                                  // Listen for success or failure
                                  subscription = _swapBloc.stream.listen((
                                    state,
                                  ) {
                                    if (state is SendswaptobitnobSuccessState) {
                                      setState(() => isSending = false);
                                      subscription?.cancel();
                                      final txid = state.txid;
                                      final timestamp = DateTime.now();
                                      print('SENDING SWAP DATA TO BACKEND');
                                      _callProceedSwap(txid, widget.userinfo['usdtAddress']);
                                     print('FINISHED SENDING TRANSACTION TO BACKEND..');

                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: kmainBackgroundcolor,
                                        builder: (_) => Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Transaction Successful",
                                                style: TextStyle(
                                                  color: kmainWhitecolor,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                "Amount Sent: $depositAmount $selectedFromCurrency",
                                                style: TextStyle(
                                                  color: kmainWhitecolor,
                                                ),
                                              ),
                                              Text(
                                                "Transaction ID: $txid",
                                                style: TextStyle(
                                                  color: kwhitecolor
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              Text(
                                                "Time: ${DateFormat('yyyy-MM-dd – kk:mm').format(timestamp)}",
                                                style: TextStyle(
                                                  color: kwhitecolor
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.greenAccent,
                                                ),
                                                child: const Text(
                                                  "Close",
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    if (state is SendswaptobitnobFailureState) {
                                      setState(() => isSending = false);
                                      subscription
                                          ?.cancel(); // ✅ cancel subscription on failure too

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Transaction failed: ${state.message}",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Confirm",
                                  style: TextStyle(color: Colors.black),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Safe area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final fromBalance = selectedFromCurrency == 'BTC'
        ? widget.btcbalance
        : widget.usdtbalance;
    final toBalance = selectedToCurrency == 'BTC'
        ? widget.btcbalance
        : widget.usdtbalance;
    final fromFormatter = selectedFromCurrency == 'BTC'
        ? btcFormatter
        : usdtFormatter;
    final toFormatter = selectedToCurrency == 'BTC'
        ? btcFormatter
        : usdtFormatter;
    final formattedFromBalance = fromFormatter.format(fromBalance);
    final formattedToBalance = toFormatter.format(toBalance);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Swaps', style: TextStyle(color: kmainWhitecolor)),
        ),
        backgroundColor: kmainBackgroundcolor,
        iconTheme: IconThemeData(color: kwhitecolor),
      ),
      backgroundColor: kmainBackgroundcolor,
      body: BlocListener<SendswaptobitnobBloc, SendswaptobitnobState>(
        bloc: _swapBloc,
        listener: (context, state) {
          if (state is SendswaptobitnobSuccessState) {
            print('Sent successfully');
          } else if (state is SendswaptobitnobFailureState) {
            _showError(state.message);
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Transfer from",
                      style: TextStyle(color: kmainWhitecolor),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: TextFormField(
                  controller: _fromAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: "0",
                    hintStyle: TextStyle(
                      color: kmainWhitecolor.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isFromInputValid ? kwhitecolor : Colors.red,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isFromInputValid ? kwhitecolor : Colors.red,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isFromInputValid ? kwhitecolor : Colors.red,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: kmainBackgroundcolor,
                        value: selectedFromCurrency,
                        items: ["BTC", "USDT"].map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text(
                              currency,
                              style: TextStyle(color: kmainWhitecolor),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedFromCurrency = value!;
                            selectedToCurrency = value == 'BTC'
                                ? 'USDT'
                                : 'BTC';
                            _debouncedValidateAndFetchQuote();
                          });
                        },
                      ),
                    ),
                  ),
                  style: TextStyle(color: kmainWhitecolor),
                ),
              ),
              if (!_isFromInputValid && _fromAmountController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 30, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        _fromErrorMessage ?? 'Invalid input',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      'Balance: $formattedFromBalance $selectedFromCurrency',
                      style: TextStyle(color: kmainWhitecolor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  customContainer(
                    45,
                    250,
                    BoxDecoration(
                      color: kwhitecolor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    Center(
                      child: Text(
                        _quoteData != null
                            ? '${_fromAmountController.text} ${selectedFromCurrency} = ${_toAmountController.text} ${selectedToCurrency}'
                            : _btcPriceUsd != null
                            ? '${_fromAmountController.text} = \$${_btcPriceUsd!.toStringAsFixed(2)}'
                            : 'Fetching price...',
                        style: TextStyle(color: kmainBackgroundcolor),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          final temp = selectedFromCurrency;
                          selectedFromCurrency = selectedToCurrency;
                          selectedToCurrency = temp;
                          _debouncedValidateAndFetchQuote();
                        });
                      },
                      icon: Icon(
                        Icons.swap_vert,
                        color: kmainWhitecolor,
                        size: 35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Transfer to",
                      style: TextStyle(color: kmainWhitecolor),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: TextFormField(
                  controller: _toAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "0",
                    hintStyle: TextStyle(
                      color: kmainWhitecolor.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: kwhitecolor, width: 2.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kwhitecolor, width: 2.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kwhitecolor, width: 2.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: kmainBackgroundcolor,
                        value: selectedToCurrency,
                        items: [selectedToCurrency].map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text(
                              currency,
                              style: TextStyle(color: kmainWhitecolor),
                            ),
                          );
                        }).toList(),
                        onChanged: null,
                      ),
                    ),
                  ),
                  style: TextStyle(color: kmainWhitecolor),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      'Balance: $formattedToBalance $selectedToCurrency',
                      style: TextStyle(color: kmainWhitecolor),
                    ),
                  ),
                ],
              ),
              if (_isLoadingQuote)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 60),
              customButtonContainer(
                50,
                300,
                BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4,
                      blurStyle: BlurStyle.solid,
                      spreadRadius: 0.9,
                      color: kwhitecolor,
                    ),
                  ],
                  color:
                      _isFromInputValid &&
                          _fromAmountController.text.isNotEmpty &&
                          !_isLoadingQuote
                      ? kmainBackgroundcolor
                      : kmainBackgroundcolor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                Center(
                  child: Text(
                    'Continue',
                    style: TextStyle(color: kmainWhitecolor),
                  ),
                ),
                _isFromInputValid &&
                        _fromAmountController.text.isNotEmpty &&
                        !_isLoadingQuote
                    ? _createSwapOrder
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
