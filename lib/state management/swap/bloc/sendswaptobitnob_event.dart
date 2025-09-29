part of 'sendswaptobitnob_bloc.dart';

@immutable
sealed class SendswaptobitnobEvent {}

class SendBtcToBitnobEvent extends SendswaptobitnobEvent {
  final String userMnemonic;
  final String depositAddress;
  final double btcAmount;
  final String fromCurrency;
  final String toCurrency;

  SendBtcToBitnobEvent( {
    required this.userMnemonic,
    required this.depositAddress,
    required this.btcAmount,
    required this.fromCurrency,
    required this.toCurrency
  });
}
