part of 'sendfunds_bloc.dart';

@immutable
sealed class SendFundstEvent {}

 final class EnsureSendFundsEvent extends SendFundstEvent{
  final String mnemonic;
   final String toAddress;
   final int ammount;
   final String? notePad;

  EnsureSendFundsEvent({required this.mnemonic,required this.toAddress, required this.ammount, required this.notePad});
 }

