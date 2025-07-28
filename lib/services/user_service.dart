import 'dart:convert';
import 'package:naipay/model/user.dart';
import 'package:http/http.dart' as http;
import 'package:naipay/model/walletmodel.dart';

class UserService {
  static const String baseurl = 'http://10.46.27.42:2000';

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

  Future<void> verifyOtp(User user) async {
  final response = await http.post(
    Uri.parse('$baseurl/auth/verify-otp'),
    headers: {'Content-Type': 'application/json'},
    body: user.toJson(), // This is fine
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
      body: user.toJson()
    );
    print(response.statusCode);
    if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print("Wallet created successfully: $responseBody");
      } else {
        final errorData = jsonDecode(response.body);
        print('Backend error: ${errorData['message']}');
        throw Exception('Failed to create wallet: ${errorData['message']}');
      }
  } catch (e) {
    print("Error occurred: $e");
    rethrow;
  }
}}
