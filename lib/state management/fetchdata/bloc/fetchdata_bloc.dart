import 'package:bloc/bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:meta/meta.dart';
import 'package:naipay/model/getusersmodels.dart';
import 'package:naipay/services/user_service.dart';
import 'package:naipay/services/walletservice.dart';

part 'fetchdata_event.dart';
part 'fetchdata_state.dart';

class FetchdataBloc extends Bloc<FetchdataEvent, FetchdataState> {
   WalletService? walletService;
   UserService? userService;
  FetchdataBloc({this.walletService,this.userService}) : super(FetchdataInitial()) {
    on<FetchUserDataEvent>(_fetchusersdata);
  }

  Future<void> _fetchusersdata(FetchUserDataEvent event ,Emitter<FetchdataState> emit)async{
    emit(FetchUsersLoadingState());
    try {
      
    final walletdata = await WalletService().createBitcoinAndTronWallet(event.email);
    final usersinfo = await UserService().getUsersInfo(Getuser(email: event.email));
    final cryptoPrice = await UserService().fetchCryptoPrices();
    final cryptoChart = await  UserService().fetchBitcoinChartData();
     bool isUpward =false;
     if(cryptoChart.length>=2){
      isUpward = cryptoChart.last.y> cryptoChart.first.x;
     }

      print("CRUTPTO PRICE IS$cryptoPrice");
      emit(FetchUsersSuccessState(walletdata: walletdata, usersInfo: usersinfo,prices:cryptoPrice,chartData:cryptoChart ,isUpward:isUpward ,));
      print(usersinfo);
    } catch (e) {
      print(e);
      emit(FetchUsersFailureState(message: e.toString()));
    }
  
  }
}
