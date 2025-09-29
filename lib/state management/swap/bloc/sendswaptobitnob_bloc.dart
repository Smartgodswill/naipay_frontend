import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:naipay/services/walletservice.dart';

part 'sendswaptobitnob_event.dart';
part 'sendswaptobitnob_state.dart';

class SendswaptobitnobBloc extends Bloc<SendswaptobitnobEvent, SendswaptobitnobState> {
  SendswaptobitnobBloc() : super(SendswaptobitnobInitial()) {
    on<SendBtcToBitnobEvent>(_onSendBtcToBitnob);
  }

  FutureOr<void> _onSendBtcToBitnob(
  SendBtcToBitnobEvent event, 
  Emitter<SendswaptobitnobState> emit
) async {
  emit(SendswaptobitnobLoadingState());

  try {
    // Send BTC via your WalletService
    final txid = await WalletService().sendBtcToBitnob(
      userMnemonic: event.userMnemonic,
      depositAddress: event.depositAddress,
      btcAmount: event.btcAmount,
    );

    print("Send to Bitnob transaction Id is $txid");

    final amount = event.btcAmount;              
    final fromCurrency = event.fromCurrency;    
    final toCurrency = event.toCurrency;       
    final timestamp = DateTime.now();           

    emit(SendswaptobitnobSuccessState(
      txid: txid,
      amount: amount,
      fromCurrency: fromCurrency??"",
      toCurrency: toCurrency??"",
      timestamp: timestamp,
    ));

  } catch (e) {
    emit(SendswaptobitnobFailureState( e.toString()));
  }
}

}
