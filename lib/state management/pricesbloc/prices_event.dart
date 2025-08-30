part of 'prices_bloc.dart';

@immutable
sealed class PricesEvent {}


class FetchPricesEvent extends PricesEvent {}
