import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naipay/subscreens/resetransactionpin.dart';
import 'package:app_links/app_links.dart';
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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.messageId}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void handleNotificationTap(Map<String, dynamic> data) {
  print('Notification tapped with data: $data');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();
  tz.initializeTimeZones();

  await _initLocalNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
      child: const MyApp(),
    ),
  );
}

Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      final data = jsonDecode(details.payload ?? '{}') as Map<String, dynamic>;
      handleNotificationTap(data);
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static Future<void> showLocalNotification(
      String title, String body, Map<String, dynamic> data) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_channel_id',
      'FCM Notifications',
      channelDescription: 'Push notifications from Bitsure',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: jsonEncode(data),
    );
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks(onAppLink: (uri, _) {
    });

    _checkAndHandleConnectivity();
    _requestNotificationPermission();
    _getDeviceToken();
    _subscribeToTopic();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        MyApp.showLocalNotification(
          message.notification!.title ?? 'Bitsure Update',
          message.notification!.body ?? 'Check the latest news!',
          message.data,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) handleNotificationTap(message.data);
    });

    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none) && mounted) {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
      }
    });
  }

  

  Future<void> _subscribeToTopic() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
      print('Subscribed to topic: all_users');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _checkAndHandleConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNetworkDialog(context);
      });
    }
  }

  void _showNetworkDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kmainBackgroundcolor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.wifi_off_outlined, color: kwhitecolor, size: 32),
              const SizedBox(width: 12),
              Text(
                'No Internet Connection',
                style: TextStyle(
                  color: kwhitecolor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Please check your network and try again.',
            style: TextStyle(color: kmainWhitecolor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final results = await Connectivity().checkConnectivity();
                if (!results.contains(ConnectivityResult.none)) {
                  Navigator.of(dialogContext).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Still no connection. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: kwhitecolor,
                backgroundColor: ksubcolor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Naipay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kwhitecolor),
      ),
      home: const RegisterScreen(),
    );
  }
}

Future<void> _getDeviceToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Registration Token: $token");
}
