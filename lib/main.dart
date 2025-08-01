import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/screens/registerscreen.dart';
import 'package:naipay/state%20management/fetchdata/bloc/fetchdata_bloc.dart';
import 'package:naipay/state%20management/onboarding/onboarding_bloc.dart';
import 'package:naipay/state%20management/restorewallet/bloc/restorewallet_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => OnboardingBloc()),
        BlocProvider(create: (context) => FetchdataBloc()),
        BlocProvider(create: (context) => RestorewalletBloc()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: RegisterScreen(),
    );
  }
}
