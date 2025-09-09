part of 'sendtransactionpin_bloc.dart';

@immutable
sealed class SendtransactionpinState {}

final class SendtransactionpinInitial extends SendtransactionpinState {}


class PinLoading extends  SendtransactionpinState {}

class PinVerified extends  SendtransactionpinState{}

class PinSetSuccessfully extends  SendtransactionpinState {}

class PinMismatch extends  SendtransactionpinState {}

class TransactionSuccess extends  SendtransactionpinState {
  final Map<String, dynamic> transactionData;
  TransactionSuccess(this.transactionData);
}

class TransactionFailure extends  SendtransactionpinState {
  final String error;
  TransactionFailure(this.error);
}

class UsdtTransactionSuccess extends  SendtransactionpinState {
  final Map<String, dynamic> transactionData;
  UsdtTransactionSuccess(this.transactionData);
}

class UsdtTransactionFailure extends  SendtransactionpinState {
  final String error;
  UsdtTransactionFailure(this.error);
}