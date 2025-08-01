import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:naipay/model/getusersmodels.dart';
import 'package:naipay/model/loginusermodels.dart';
import 'package:naipay/model/registerusermodels.dart';
import 'package:http/http.dart' as http;
import 'package:naipay/model/walletmodel.dart';

class UserService {
  static const String baseurl = 'http://10.193.211.102:2000';

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
    final requestBody = jsonEncode({'email': user.email!.toLowerCase()});

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

  Future<Map<String, double>> fetchCryptoPrices() async {
    final url = Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,tether&vs_currencies=usd',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final btcRaw = data['bitcoin']?['usd'];
        final usdtRaw = data['tether']?['usd'];

        double btcPrice = (btcRaw is num) ? btcRaw.toDouble() : 0.0;
        double usdtPrice = (usdtRaw is num) ? usdtRaw.toDouble() : 0.0;
        double satPrice = btcPrice / 100000000;

        return {'BTC': btcPrice, 'SAT': satPrice, 'USDT': usdtPrice};
      } else {
        print(' HTTP Error: ${response.statusCode}');
        print(' Response Body: ${response.body}');
        throw Exception('Failed to fetch prices from CoinGecko');
      }
    } catch (e) {
      print(' Exception during HTTP call: $e');
      throw Exception('Unknown error occurred');
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


}
