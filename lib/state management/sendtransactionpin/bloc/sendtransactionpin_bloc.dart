import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/services/walletservice.dart';

part 'sendtransactionpin_event.dart';
part 'sendtransactionpin_state.dart';

class SendtransactionpinBloc
    extends Bloc<SendtransactionpinEvent, SendtransactionpinState> {
  SendtransactionpinBloc() : super(SendtransactionpinInitial()) {
    on<VerifyPinEvent>(_onVerifyPin);
    on<SendBTCTransactionEvent>(_onSendTransaction);
  }

  Future<void> _onVerifyPin(
      VerifyPinEvent event, Emitter<SendtransactionpinState> emit) async {
    emit(PinLoading());
    try {
      await UserService().verifyTransactionPin(event.email, event.pin);
      emit(PinVerified());
    } catch (e) {
      emit(TransactionFailure("Failed to verify PIN: $e"));
    }
  }

  Future<void> _onSendTransaction(
      SendBTCTransactionEvent event, Emitter<SendtransactionpinState> emit) async {
    emit(PinLoading());
    try {
      Map<String, dynamic> txResult;
      Map<String, dynamic> updatedWalletInfo;
      Map<String, dynamic> txData;

      print("🟡 Incoming transaction request:");
      print("Coin: ${event.coin}");
      print("Amount (raw): ${event.amount}");
      print("From: ${event.fromAddress}");
      print("To: ${event.toAddress}");
      print("Wallet Info: ${event.walletInfo}");
      print("Preview Data: ${event.previewData}");

      if (event.coin.toUpperCase() == 'BTC') {
        print("⚙️ Handling BTC transaction...");

        txResult = await WalletService().confirmTransaction(
          psbt: event.previewData['psbt'],
          wallet: event.previewData['wallet'],
          blockchain: event.previewData['blockchain'],
        );

        print("✅ BTC txResult from WalletService: $txResult");

        final currentBalanceSats = event.walletInfo['balance_sats'] ?? 0;
        final amountInSats = event.amount;

        // DEBUG: Check what fee key exists
        print("🔍 Checking previewData fee keys...");
        event.previewData.forEach((k, v) {
          print("  ➤ $k : $v");
        });

        final feeInSats = event.previewData['fee'] ??
            event.previewData['fee_sats'] ??
            event.previewData['networkFee'] ??
            event.previewData['txFee'] ??
            0;

        print("💰 Parsed feeInSats: $feeInSats");

        final updatedBalanceSats = currentBalanceSats - (amountInSats + feeInSats);
        print("🔹 Updated Balance Sats: $updatedBalanceSats");

        final updatedTransactionHistory = [
          ...(event.walletInfo['transaction_history'] ?? []),
          {
            'txid': txResult['txid'],
            'fromAddress': event.fromAddress,
            'toAddress': event.toAddress,
            'amount': amountInSats,
            'fee': feeInSats ,
            'coin': 'BTC',
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'pending',
          },
        ];

        updatedWalletInfo = {
          ...event.walletInfo,
          'balance_sats': updatedBalanceSats,
          'transaction_history': updatedTransactionHistory,
        };

        txData = {
          'fromAddress': event.fromAddress,
          'toAddress': event.toAddress,
          'amount': (amountInSats / 100000000).toStringAsFixed(8),
          'fee': (feeInSats / 100000000).toStringAsFixed(8),
          'coin': 'BTC',
          'txid': txResult['txid'],
          'status': 'pending',
          'updatedWalletInfo': updatedWalletInfo,
        };

        print("🧾 Final BTC txData being emitted: $txData");

      } else if (event.coin.toUpperCase() == 'USDT') {
        print("⚙️ Handling USDT transaction...");

        txResult = await UserService().sendTrc20Transaction(
          email: event.email,
          toAddress: event.toAddress,
          amount: event.amount,
        );

        print("✅ Full txResult: $txResult");
        print("Tx Result ID: ${txResult["trc20Transactions"]?[0]?["txid"]}");

        if (!(txResult['success'] ?? false)) {
          throw Exception(txResult['error'] ?? 'USDT transaction failed');
        }

        final currentBalance = double.tryParse(event.walletInfo['usdt_balance'].toString()) ?? 0.0;
        final fee = double.tryParse(txResult['feeUSDT'].toString()) ?? 0.0;
        final updatedBalance = currentBalance - event.amount - fee;

        final fromAddress = event.walletInfo['usdtAddress'] ?? event.fromAddress ?? '';
        final updatedTransactionHistory = txResult['trc20Transactions'] ?? [];

        if (updatedTransactionHistory.isNotEmpty &&
            event.amount != double.tryParse(updatedTransactionHistory.first['amount'] ?? '0')) {
          print('⚠️ Warning: Mismatched amount: request (${event.amount}) vs backend (${updatedTransactionHistory.first['amount']})');
        }

        print('Updated trc20Transactions from backend: $updatedTransactionHistory');

        final transaction = updatedTransactionHistory.isNotEmpty ? updatedTransactionHistory.first : {};

        updatedWalletInfo = {
          ...event.walletInfo,
          'usdt_balance': updatedBalance,
          'trc20Transactions': updatedTransactionHistory,
        };

        txData = {
          'fromAddress': transaction['fromAddress'] ?? fromAddress,
          'toAddress': transaction['toAddress'] ?? event.toAddress,
          'amount': transaction['amount'] ?? event.amount.toStringAsFixed(6),
          'fee': transaction['fee'] ?? fee.toStringAsFixed(6),
          'coin': 'USDT',
          'txid': transaction['txid'] ?? txResult['txTransfer'] ?? txResult['txid'] ?? 'N/A',
          'status': transaction['status'] ?? 'confirmed',
          'updatedWalletInfo': updatedWalletInfo,
        };

        print("🧾 Final USDT txData being emitted: $txData");
      } else {
        emit(TransactionFailure("Coin ${event.coin} not supported"));
        return;
      }

      emit(TransactionSuccess(txData));
    } catch (e, stack) {
      print("❌ Transaction failed: $e");
      print("📚 Stack trace: $stack");
      emit(TransactionFailure("Transaction failed: $e"));
    }
  }
}
