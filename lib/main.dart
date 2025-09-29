
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naipay/screens/registerscreen.dart';
import 'package:naipay/state%20management/fetchdata/bloc/fetchdata_bloc.dart';
import 'package:naipay/state%20management/onboarding/onboarding_bloc.dart';
import 'package:naipay/state%20management/pricesbloc/prices_bloc.dart';
import 'package:naipay/state%20management/restorewallet/bloc/restorewallet_bloc.dart';
import 'package:naipay/state%20management/sendfunds/bloc/sendfunds_bloc.dart';
import 'package:naipay/state%20management/sendtransactionpin/bloc/sendtransactionpin_bloc.dart';
import 'package:naipay/state%20management/swap/bloc/sendswaptobitnob_bloc.dart';
import 'package:naipay/theme/colors.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => OnboardingBloc()),
        BlocProvider(create: (context) => FetchdataBloc()),
        BlocProvider(create: (context) => RestorewalletBloc()),
        BlocProvider(create: (context) => PricesBloc()),
        BlocProvider(create: (context) => SendfundsBloc()),
        BlocProvider(create: (context) => SendtransactionpinBloc()),
        BlocProvider(create: (context) => SendswaptobitnobBloc()),

      ],
      child: const MyApp()),
  
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kwhitecolor),
      ),
      home: RegisterScreen()
    );
  }
}