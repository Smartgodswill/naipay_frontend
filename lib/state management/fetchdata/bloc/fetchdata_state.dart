part of 'fetchdata_bloc.dart';

@immutable
sealed class FetchdataState {}

final class FetchdataInitial extends FetchdataState {}

class FetchUsersLoadingState extends FetchdataState {}

class FetchUsersSuccessState extends FetchdataState {
  final Map<String, dynamic> walletdata;
  final Map<String, dynamic> usersInfo;
  final List<dynamic> trc20Transactions;
  
  FetchUsersSuccessState(
     {
    required this.walletdata,
    required this.usersInfo,
    required this.trc20Transactions
    
  });
}

class FetchUsersFailureState extends FetchdataState {
  final String message;
  FetchUsersFailureState({required this.message});
}
