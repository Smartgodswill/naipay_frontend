import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:naipay/model/getusersmodels.dart';
import 'package:naipay/model/loginusermodels.dart';
import 'package:naipay/services/restorewallet_service.dart';
import 'package:naipay/services/userapi_service.dart';
import 'package:naipay/services/walletservice.dart';

part 'restorewallet_event.dart';
part 'restorewallet_state.dart';

class RestorewalletBloc extends Bloc<RestorewalletEvent, RestorewalletState> {
  RestorewalletBloc() : super(RestorewalletInitial()) {
    on<RestoreUsersWalletOtpEvent>(_restoreOtpSentWallet);
    on<RestoreUsersWalletVerifyOtpEvent>(_restorVerifedwallet);
  }
  String? validatePassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{10,}$',
    );


    if (!regex.hasMatch(password)) {
      return 'Password must be at least 10 characters long and include:\n• 1 uppercase letter\n• 1 lowercase letter\n• 1 number\n• 1 special character';
    }

    return null;
  }

  Future<void> _restoreOtpSentWallet(RestoreUsersWalletOtpEvent event ,Emitter<RestorewalletState> emit)async{
    final passwordError = validatePassword(event.password);
    if(event.email.isEmpty && event.password.isEmpty){
        emit(RestorewalletFailureState('please input your credentials correctly'));
    return;
    }else if(event.password.length < 8 ){
      emit(RestorewalletFailureState('Your password must be at lease 8 character long'));
    return;
    }
    if (passwordError != null) {
      emit(RestorewalletFailureState(passwordError));
      return;
    }
    try {
       await UserService().login(LoginUserModels(email: event.email,password: event.password,));
      emit(RestorewalletSuccessState());
    } catch (e) {
      print(e);
      emit(RestorewalletFailureState('$e'));
      
    }
  }
  Future<void> _restorVerifedwallet(RestoreUsersWalletVerifyOtpEvent event ,Emitter<RestorewalletState> emit)async{

    emit(RestorewalleLoadingState());
    try {
      WalletService().resetWallet();
      final result=  await UserService().verifyLogInOtp(LoginUserModels(email: event.email,otp: event.otp));
      final String mnemonics = result['mnemonic'] ?? '';
      print(mnemonics);
      final userInfo = await UserService().getUsersInfo(Getuser(email: event.email));
      print(userInfo['email']);
      final walletdata=   await RestorewalletService().restoreWallet(mnemonics,userInfo['bitcoin_descriptor'],userInfo['email'],);
      print('Bitcoin data is:$walletdata');
      emit(RestoreVerifiedwalletSuccessState(walletdata,userInfo));
    } catch (e) {
      print(e);
      emit(RestorewalletFailureState('RestorewalletFailureState on bitcoinpalava$e'));
      
    }
  }
}
