import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:naipay/model/getusersmodels.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/services/walletservice.dart';
import 'package:bdk_flutter/bdk_flutter.dart';
part 'fetchdata_event.dart';
part 'fetchdata_state.dart';

class FetchdataBloc extends Bloc<FetchdataEvent, FetchdataState> {
  WalletService? walletService;
  UserService? userService;
  final Map<String, dynamic>? trc20Transactions;  

  FetchdataBloc( {this.walletService, this.userService,this.trc20Transactions,})
    : super(FetchdataInitial()) {
    on<FetchUserDataEvent>(_fetchusersdata);
  }

  Future<void> _fetchusersdata(
    FetchUserDataEvent event,
    Emitter<FetchdataState> emit,
  ) async {
    emit(FetchUsersLoadingState());
    try {
      final usersinfo = await UserService().getUsersInfo(
        Getuser(email:event.email ?? ''),
      );

      final String mnemonic = usersinfo['mnemonic'];

      print(' this particular wallet data is: ${mnemonic}');
      if (mnemonic.isEmpty) {
        throw Exception('mnemonic not found to fetch wallet');
      }
      final walletdata = await WalletService().loadExistingWallet(
        event.email,
        mnemonic,
        Network.Testnet,
      );
      print(walletdata);
      print(usersinfo['usdtAddress']);
      final String address = usersinfo['usdtAddress'];
      print(address);
       final transactions = await UserService().fetchTRC20TransactionHistory(address);
       print("get it: $transactions");
      emit(
        FetchUsersSuccessState(walletdata: walletdata, usersInfo: usersinfo,trc20Transactions:transactions ),
      );
      print(usersinfo);
      print(transactions);
    } catch (e, stackTrace) {
      print('Error in FetchdataBloc: $e\nStackTrace: $stackTrace');
      emit(FetchUsersFailureState(message: e.toString()));
    }
  }
}
