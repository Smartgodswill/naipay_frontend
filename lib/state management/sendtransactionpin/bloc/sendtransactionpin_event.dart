part of 'sendtransactionpin_bloc.dart';

@immutable
sealed class SendtransactionpinEvent {}


class VerifyPinEvent extends SendtransactionpinEvent {
  final String email;
  final String pin;
  VerifyPinEvent(this.email, this.pin);
}

class SetNewPinEvent extends SendtransactionpinEvent {
  final String email;
  final String pin;
  SetNewPinEvent(this.email, this.pin);
}

class ConfirmPinEvent extends SendtransactionpinEvent {
  final String email;
  final String firstPin;
  final String secondPin;
  ConfirmPinEvent(this.email, this.firstPin, this.secondPin);
}

class SendTransactionEvent extends SendtransactionpinEvent {
  final Map<String, dynamic> previewData;
  final String fromAddress;
  final String toAddress;
  final int amount;
  final String coin;
  final Map<String, dynamic> walletInfo;

  SendTransactionEvent( {
    required this.previewData,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.coin,
    required this.walletInfo
  });
}