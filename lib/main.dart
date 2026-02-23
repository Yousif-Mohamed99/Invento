import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:invento/core/injection_container.dart' as di;
import 'package:invento/core/injection_container.dart';
import 'package:invento/features/auth/presentation/pages/login_screen.dart';
import 'package:invento/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:invento/features/home/presentation/pages/main_wrapper.dart';
import 'package:invento/features/products/presentation/bloc/orders_bloc.dart';
import 'package:invento/features/products/presentation/bloc/orders_event.dart';
import 'package:invento/features/products/presentation/bloc/products_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:invento/features/products/presentation/bloc/products_event.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  timeago.setLocaleMessages('ar', timeago.ArMessages());
  await Firebase.initializeApp();

  await di.init();

  await dotenv.load(fileName: ".env");
  await FirebaseAppCheck.instance.activate(
    // للأندرويد: استخدم PlayIntegrity للأمان
    providerAndroid: AndroidPlayIntegrityProvider(),
    // للآيفون (iOS)
    providerApple: AppleDeviceCheckProvider(),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => sl<AuthBloc>()),

        BlocProvider<ProductsBloc>(
          create: (context) => sl<ProductsBloc>()..add(LoadProductsEvent()),
        ),
        BlocProvider<OrdersBloc>(
          create: (context) => sl<OrdersBloc>()..add(LoadOrdersEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'Invento',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.blueAccent,
          useMaterial3: true,
          fontFamily: 'Cairo',
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'AE'), // Arabic
        ],
        locale: const Locale('ar', 'AE'),

        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData) {
              return const MainWrapper();
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
