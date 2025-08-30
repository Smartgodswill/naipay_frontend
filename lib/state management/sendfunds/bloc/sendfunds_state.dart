part of 'sendfunds_bloc.dart';

@immutable
sealed class SendFundState {}

final class SendfundsInitialState extends SendFundState {}


 final class SendFundsLoadingState extends SendFundState{}

 final class SendFundsSuccessState extends SendFundState{
   final Map<String,dynamic> result;
   SendFundsSuccessState({
    required this.result
   });
 }



 final class SendFundsFailureState extends SendFundState{
  final String  message;
  SendFundsFailureState(this.message);
 }
