part of 'fetchdata_bloc.dart';

@immutable
sealed class FetchdataEvent {}


class FetchUserDataEvent extends FetchdataEvent{
  final String email;
  FetchUserDataEvent({
   required this.email,
  });
}

