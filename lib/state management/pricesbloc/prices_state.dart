part of 'prices_bloc.dart';

@immutable
sealed class PricesState {}

final class PricesInitial extends PricesState {}


final class PricesLoadingState extends PricesState {}

final class PricesLoadedSuccessState extends PricesState {
  final Map<String,Map<String,dynamic>> prices;

  PricesLoadedSuccessState({
   required this.prices
  });
}


final class PricesErrorState extends PricesState {
  final String message;

  PricesErrorState(this.message);
}