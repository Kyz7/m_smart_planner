// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/places_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/itinerary_screen.dart';
import 'screens/splash_screen.dart';
import 'models/place.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PlacesProvider()),
      ],
      child: MaterialApp(
        title: 'Travel Planner',
        debugShowCheckedModeBanner: false,
        
        // Add localization delegates
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        // Add supported locales
        supportedLocales: [
          Locale('en', 'US'), // English (default)
          Locale('id', 'ID'), // Indonesian
        ],
        
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Color(0xFF2563EB),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/home': (context) => HomeScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/itinerary': (context) => ItineraryScreen(),
        },
        onGenerateRoute: (settings) {
          final place = settings.arguments as Place?;
          if (settings.name!.startsWith('/detail/')) {
            final placeId = settings.name!.split('/')[2];
            return MaterialPageRoute(
              builder: (context) => DetailScreen(
                place: place,
                placeId: placeId,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}