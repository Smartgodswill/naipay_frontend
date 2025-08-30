part of 'restorewallet_bloc.dart';

@immutable
sealed class RestorewalletState {}

final class RestorewalletInitial extends RestorewalletState {}
final class RestorewalleLoadingState extends RestorewalletState {
  final String message;
  RestorewalleLoadingState(this.message);
}

final class RestorewalletSuccessState extends RestorewalletState {
}
final class RestoreVerifiedwalletSuccessState extends RestorewalletState {
  final Map<String,dynamic> mnemonic;
  final Map<String,dynamic> userInfo;
  RestoreVerifiedwalletSuccessState(this.mnemonic, this.userInfo);
}

final class RestorewalletFailureState extends RestorewalletState {
  final  String message;
   RestorewalletFailureState(this.message);
}