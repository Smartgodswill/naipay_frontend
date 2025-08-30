import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:naipay/services/userapi_service.dart';

part 'prices_event.dart';
part 'prices_state.dart';

class PricesBloc extends Bloc<PricesEvent, PricesState> {
  PricesBloc() : super(PricesInitial()) {
    on<PricesEvent>(_onFetchPrices);
  }

  FutureOr<void> _onFetchPrices(PricesEvent event, Emitter<PricesState> emit)async {
    emit(PricesLoadingState());

    try {
      final price = await UserService().fetchCryptoPriceAndData();
      emit(PricesLoadedSuccessState(prices: price));
      print(price);
    } catch (e) {
       emit(PricesErrorState(e.toString()));
    }
  }
}
