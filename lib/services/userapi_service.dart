import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:naipay/model/getusersmodels.dart';
import 'package:naipay/model/loginusermodels.dart';
import 'package:naipay/model/registerusermodels.dart';
import 'package:http/http.dart' as http;
import 'package:naipay/model/walletmodel.dart';

class UserService {
  static const String baseurl = "http://10.139.131.94:2000";


   Future<Map<String, dynamic>> sendTrc20Transaction({
    required String email,
    required String toAddress,
    required int amount,
  }) async {
    final url = Uri.parse("$baseurl/auth/send-trc20-transactions");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "toAddress": toAddress,
          "amount": amount.toString(), 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          return data; // { success, txFee, txTransfer, feeUSDT, newBalance }
        } else {
          throw Exception(data["error"] ?? "Transaction failed");
        }
      } else {
        throw Exception("Error: ${response.body}");
      }
    } catch (e) {
      throw Exception("⚠️ Exception while sending: $e");
    }
  }


  Future<void> signup(User user) async {
    final response = await http.post(
      Uri.parse('$baseurl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: user.toJson(),
    );

    print("Status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Unknown error occurred';
        throw Exception(message);
      } catch (e) {
        throw Exception('Failed to register user $e');
      }
    }

    print("User registered successfully!");
  }

  Future<void> verifyRegisterOtp(User user) async {
    final response = await http.post(
      Uri.parse('$baseurl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: user.toJson(), 
    );

    print("Status code: ${response.statusCode}");
    print("Response body: ${response.body}");
    print("OTP sent to backend: ${user.otp}");

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Unknown error occurred';
        print(message);
        throw Exception(message);
      } catch (e) {
        throw Exception('Failed to verify OTP: $e');
      }
    }

    print("OTP verified successfully!");
  }

  Future<void> createWalletAndSendToBackend(Walletmodel user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseurl/auth/create-wallet'),
        headers: {'Content-Type': 'application/json'},
        body: user.toJson(),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print("Wallet created successfully: $responseBody");
      } else {
        if (response.statusCode != 200) {
          final data = jsonDecode(response.body);
          final message =
              data['message'] ?? data['error'] ?? 'Unknown error occurred';
          throw Exception(message);
        }
      }
    } catch (e) {
      print("Error occurred: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUsersInfo(Getuser user) async {
    final requestBody = jsonEncode({'email': user.email?.toLowerCase()});

    print('Sending JSON: $requestBody');

    final response = await http.post(
      Uri.parse('$baseurl/auth/get-users-info'),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      final message = data['message'] ?? 'Unknown error occurred';
      throw Exception(message);
    }

    return jsonDecode(response.body);
  }



Future<Map<String, Map<String, dynamic>>> fetchCryptoPriceAndData() async {
  final url = Uri.parse(
    'https://api.coingecko.com/api/v3/coins/markets'
    '?vs_currency=usd&ids=bitcoin,tether',
  );

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    Map<String, Map<String, dynamic>> result = {};
    for (var coin in data) {
      final symbol = coin['symbol'].toString().toUpperCase();
      final price = (coin['current_price'] as num).toDouble();
      final satPrice = symbol == 'BTC' ? price / 100000000 : null;

      result[symbol] = {
        'price': price,
        if (satPrice != null) 'sat': satPrice,
        'change_24h': coin['price_change_percentage_24h'],
        'rank': coin['market_cap_rank'],
      };
    }

    return result;
  } else {
    throw Exception('Failed to fetch data');
  }
}


  Future<List<FlSpot>> fetchBitcoinChartData() async {
  final response = await http.get(Uri.parse(
    'https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=1'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List prices = data['prices'];

    return prices.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final price = entry.value[1].toDouble(); 
      return FlSpot(index, price);
    }).toList();
  } else {
    throw Exception('Failed to fetch Bitcoin data');
  }
}

Future<void> login(LoginUserModels user) async{
  final response = await http.post(Uri.parse('$baseurl/auth/send-otp-login'),
  headers: {'Content-Type': 'application/json'},
  body:  user.toJson());
  print(response);
  print("Status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Unknown error occurred';
        throw Exception(message);
      } catch (e) {
        throw Exception(' $e');
      }
    }

    print("User LogIn successfully!");
}
Future<Map<String, dynamic>> verifyLogInOtp(LoginUserModels user) async {
    final response = await http.post(
      Uri.parse('$baseurl/auth/verify-otp-login'),
      headers: {'Content-Type': 'application/json'},
      body: user.toJson(), 
    );

    print("Status code: ${response.statusCode}");
    print("Response body: ${response.body}");
    print("OTP sent to backend: ${user.otp}");
  

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Unknown error occurred';
        print(message);
        throw Exception(message);
      } catch (e) {
        throw Exception('Failed to verify OTP: $e');
      }
    }
     print("OTP verified successfully!");
      return jsonDecode(response.body);
   
  }


Future<List<dynamic>> fetchTRC20TransactionHistory(String address) async {
  try {
    final url = Uri.parse("$baseurl/auth/usdt-transactions-history");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "address": address,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];  
      } else {
        return []; // no transactions
      }
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching TRC20 history: $e");
  }
}
  Future<double> fetchUsdtFee({
  required String email,
  required String toAddress,
  required double amount,
}) async {
  final response = await http.post(
    Uri.parse('$baseurl/auth/display-estimatedFee'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'toAddress': toAddress,
      'amount': amount.toString(),
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return double.parse(data['summary']['feeUSDT']);
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch fee');
    }
  } else {
    throw Exception('Server error: ${response.statusCode}');
  }
}


 Future<void> sendPinToBackend(String email, String pin) async {
  final url = Uri.parse("$baseurl/auth/set-transaction-pin"); 
  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "pin": pin,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("PIN set successfully: $data");
    } else {
      print(" Error: ${response.body}");
    }
  } catch (e) {
    print(" Exception: $e");
  }
}
Future<bool> verifyTransactionPin(String email, String pin) async {
  final url = Uri.parse("$baseurl/auth/verify-transaction-pin"); 
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "email": email,
      "pin": pin,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["success"] == true;
  } else {
    throw Exception("Failed to verify PIN: ${response.body}");
  }
}




}