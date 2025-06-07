import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/places_provider.dart';
import 'providers/itinerary_provider.dart'; // ✅ Add this import
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/itinerary_screen.dart'; // ✅ Add this import
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
        ChangeNotifierProvider(create: (_) => ItineraryProvider()), // ✅ Add this provider
      ],
      child: MaterialApp(
        title: 'Travel App',
        debugShowCheckedModeBanner: false,
        // Add Indonesian localization
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('id', 'ID'), // Indonesian
          Locale('en', 'US'), // English
        ],
        locale: Locale('id', 'ID'), // Default to Indonesian
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(),
        onGenerateRoute: (settings) {
          // Handle route untuk detail place
          if (settings.name?.startsWith('/detail/') == true) {
            final place = settings.arguments as Place;
            return MaterialPageRoute(
              builder: (context) => PlaceDetailScreen(place: place),
              settings: settings,
            );
          }
          
          // Route lainnya...
          switch (settings.name) {
            case '/home':
              return MaterialPageRoute(builder: (context) => HomeScreen());
            case '/login':
              return MaterialPageRoute(builder: (context) => LoginScreen());
            case '/register':
              return MaterialPageRoute(builder: (context) => RegisterScreen());
            case '/itinerary':
              return MaterialPageRoute(builder: (context) => ItineraryScreen()); // ✅ Enable this route
            default:
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: Text('Route not found: ${settings.name}'),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}