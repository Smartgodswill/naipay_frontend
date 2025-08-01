part of 'fetchdata_bloc.dart';

@immutable
sealed class FetchdataState {}

final class FetchdataInitial extends FetchdataState {}

class FetchUsersLoadingState extends FetchdataState {}

class FetchUsersSuccessState extends FetchdataState {
  final Map<String, dynamic> walletdata;
  final Map<String, dynamic> usersInfo;
  final Map<String, double> prices;
  final List<FlSpot> chartData;
  final bool isUpward;
  FetchUsersSuccessState(
     {
    required this.walletdata,
    required this.usersInfo,
    required this.prices,
    required this.chartData,
     required this.isUpward,
  });
}

class FetchUsersFailureState extends FetchdataState {
  final String message;
  FetchUsersFailureState({required this.message});
}
