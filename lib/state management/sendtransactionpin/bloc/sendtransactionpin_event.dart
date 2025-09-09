part of 'sendtransactionpin_bloc.dart';

@immutable
sealed class SendtransactionpinEvent {}

class VerifyPinEvent extends SendtransactionpinEvent {
  final String email;
  final String pin;
  final SendBTCTransactionEvent? sendTransactionEvent; // optional
  final SendUsdtTransactionEvent? sendUsdtTransactionEvent;
  VerifyPinEvent(this.email, this.pin, {this.sendTransactionEvent,this.sendUsdtTransactionEvent});
}

class SetNewPinEvent extends SendtransactionpinEvent {
  final String email;
  final String pin;
  final SendBTCTransactionEvent? sendTransactionEvent; // optional
  SetNewPinEvent(this.email, this.pin, {this.sendTransactionEvent, });
}

class ConfirmPinEvent extends SendtransactionpinEvent {
  final String email;
  final String firstPin;
  final String secondPin;
  final SendBTCTransactionEvent? sendTransactionEvent; // optional
  ConfirmPinEvent(this.email, this.firstPin, this.secondPin, {this.sendTransactionEvent});
}

class SendBTCTransactionEvent extends SendtransactionpinEvent {
  final String email;
  final Map<String, dynamic> previewData;
  final String fromAddress;
  final String toAddress;
  final int amount;
  final String coin;
  final Map<String, dynamic> walletInfo;

  SendBTCTransactionEvent( {
    required this.email,
    required this.previewData,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.coin,
    required this.walletInfo,
  });
}

class SendUsdtTransactionEvent extends SendtransactionpinEvent {
  final String email;
  final Map<String, dynamic> previewData;
  final Map<String, dynamic> walletInfo;
  final String fromAddress;
  final String toAddress;
  final int amount;

  SendUsdtTransactionEvent({
    required this.email,
    required this.previewData,
    required this.walletInfo,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
  });
}

