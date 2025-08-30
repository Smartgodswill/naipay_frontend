import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:naipay/services/walletservice.dart';

part 'sendfunds_event.dart';
part 'sendfunds_state.dart';

class SendfundsBloc extends Bloc<SendFundstEvent, SendFundState> {
  SendfundsBloc() : super(SendfundsInitialState()) {
  on<EnsureSendFundsEvent>(_sendBitcoin);
  }

  

  FutureOr<void> _sendBitcoin(EnsureSendFundsEvent event, Emitter<SendFundState> emit) async{

    emit(SendFundsLoadingState());
    try {
      final result = await WalletService().previewTransaction(userMnemonic: event.mnemonic, recipientAddress: event.toAddress, amountInSats:event.ammount);
      print(result);
      emit(SendFundsSuccessState(result: result));
    } catch (e) {
      print('$e');
      emit(SendFundsFailureState('could not get fee $e'));
    }
  }
}