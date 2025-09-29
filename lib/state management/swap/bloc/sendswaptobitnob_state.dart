part of 'sendswaptobitnob_bloc.dart';

@immutable
sealed class SendswaptobitnobState {}

final class SendswaptobitnobInitial extends SendswaptobitnobState {}

final class SendswaptobitnobLoadingState extends SendswaptobitnobState {}

final class SendswaptobitnobSuccessState extends SendswaptobitnobState {
   final String txid;
  final double amount; 
  final String fromCurrency;
  final String toCurrency;
  final DateTime timestamp;

  SendswaptobitnobSuccessState({
     required this.txid,
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.timestamp,
  });
}

final class SendswaptobitnobFailureState extends SendswaptobitnobState {
  final String message;

  SendswaptobitnobFailureState(this.message);
}


