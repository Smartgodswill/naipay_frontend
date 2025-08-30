import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/services/walletservice.dart';

part 'sendtransactionpin_event.dart';
part 'sendtransactionpin_state.dart';

class SendtransactionpinBloc extends Bloc<SendtransactionpinEvent, SendtransactionpinState> {
  SendtransactionpinBloc() : super(SendtransactionpinInitial()) {
    on<VerifyPinEvent>(_onVerifyPin);
    on<SetNewPinEvent>(_onSetNewPin);
    on<ConfirmPinEvent>(_onConfirmPin);
    on<SendTransactionEvent>(_onSendTransaction);
  }

  Future<void> _onVerifyPin(VerifyPinEvent event, Emitter emit) async {
    emit(PinLoading());
    try {
      await UserService().verifyTransactionPin(event.email, event.pin);
      emit(PinVerified());
    } catch (e) {
      emit(TransactionFailure("❌ Failed to verify PIN: $e"));
    }
  }

  Future<void> _onSetNewPin(SetNewPinEvent event, Emitter emit) async {
    emit(PinLoading());
    try {
      await UserService().sendPinToBackend(event.email, event.pin);
      emit(PinSetSuccessfully());
    } catch (e) {
      emit(TransactionFailure("❌ Failed to set PIN: $e"));
    }
  }

  Future<void> _onConfirmPin(ConfirmPinEvent event, Emitter emit) async {
    if (event.firstPin == event.secondPin) {
      add(SetNewPinEvent(event.email, event.firstPin));
    } else {
      emit(PinMismatch());
    }
  }

  Future<void> _onSendTransaction(SendTransactionEvent event, Emitter emit) async {
    emit(PinLoading());
    try {
      if (event.coin != 'BTC') {
        emit(TransactionFailure("❌ Only BTC supported"));
        return;
      }

      // Send transaction
      final txResult = await WalletService().confirmTransaction(
        psbt: event.previewData['psbt'],
        wallet: event.previewData['wallet'],
        blockchain: event.previewData['blockchain'],
      );

      // Calculate updated balance locally
      final currentBalanceSats = event.walletInfo['balance_sats'] ?? 0;
      final amountInSats = event.amount;
      final feeInSats = event.previewData['fee'] ?? 0;
      final updatedBalanceSats = currentBalanceSats - (amountInSats + feeInSats);

      // Update transaction history with pending status
      final updatedTransactionHistory = [
        ...(event.walletInfo['transaction_history'] ?? []),
        {
          'txid': txResult['txid'],
          'fromAddress': event.fromAddress,
          'toAddress': event.toAddress,
          'amount': (amountInSats / 100000000).toStringAsFixed(8),
          'fee': (feeInSats / 100000000).toStringAsFixed(8),
          'coin': event.coin,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'pending', // Mark as pending
        },
      ];

      // Update walletInfo
      final updatedWalletInfo = {
        ...event.walletInfo,
        'balance_sats': updatedBalanceSats,
        'transaction_history': updatedTransactionHistory,
      };

      // Prepare transaction data
      final txData = {
        'fromAddress': event.fromAddress,
        'toAddress': event.toAddress,
        'amount': (amountInSats / 100000000).toStringAsFixed(8),
        'fee': (feeInSats / 100000000).toStringAsFixed(8),
        'coin': event.coin,
        'txid': txResult['txid'],
        'status': 'pending',
        'updatedWalletInfo': updatedWalletInfo, // Include updated wallet info
      };

      emit(TransactionSuccess(txData));
    } catch (e) {
      emit(TransactionFailure("❌ Transaction failed: $e"));
    }
  }
}