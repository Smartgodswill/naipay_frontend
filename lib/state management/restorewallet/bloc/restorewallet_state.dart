part of 'restorewallet_bloc.dart';

@immutable
sealed class RestorewalletState {}

final class RestorewalletInitial extends RestorewalletState {}
final class RestorewalleLoadingState extends RestorewalletState {}

final class RestorewalletSuccessState extends RestorewalletState {
}
final class RestoreVerifiedwalletSuccessState extends RestorewalletState {
  final String mnemonic;
  RestoreVerifiedwalletSuccessState(this.mnemonic);
}

final class RestorewalletFailureState extends RestorewalletState {
  final  String message;
   RestorewalletFailureState(this.message);
}