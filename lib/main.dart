// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/places_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/itinerary_screen.dart';
import 'screens/splash_screen.dart';
import 'models/place.dart';
void main() {
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