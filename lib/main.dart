import 'dart:io';

import 'package:country_code_picker/country_localizations.dart';
import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Constant.dart';
import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Provider/CategoryProvider.dart';
import 'package:eshop/Provider/FavoriteProvider.dart';
import 'package:eshop/Provider/FlashSaleProvider.dart';
import 'package:eshop/Provider/HomeProvider.dart';
import 'package:eshop/Provider/OfferImagesProvider.dart';
import 'package:eshop/Provider/ProductDetailProvider.dart';
import 'package:eshop/Provider/ProductProvider.dart';

import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/MemberRegistration.dart';
import 'package:eshop/Screen/MyBonus.dart';
import 'package:eshop/Screen/MyNetworks.dart';
import 'package:eshop/Screen/MyOrders.dart';

import 'package:eshop/Screen/Splash.dart';
import 'package:eshop/ui/styles/themedata.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/Demo_Localization.dart';
import 'Helper/PushNotificationService.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';

import 'Provider/Theme.dart';
import 'Provider/SettingProvider.dart';
import 'Provider/order_provider.dart';
import 'Screen/Dashboard.dart';
import 'Screen/Login.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initializedDownload();
  HttpOverrides.global = MyHttpOverrides();
  FirebaseMessaging.onBackgroundMessage(myForgroundMessageHandler);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // status bar color
  ));
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (BuildContext context) {
        String? theme = prefs.getString(APP_THEME);

        if (theme == DARK) {
          ISDARK = "true";
        } else if (theme == LIGHT) {
          ISDARK = "false";
        }

        if (theme == null || theme == "" || theme == DEFAULT_SYSTEM) {
          prefs.setString(APP_THEME, DEFAULT_SYSTEM);
          var brightness = SchedulerBinding.instance.window.platformBrightness;
          ISDARK = (brightness == Brightness.dark).toString();

          return ThemeNotifier(ThemeMode.system);
        }

        return ThemeNotifier(theme == LIGHT ? ThemeMode.light : ThemeMode.dark);
      },
      child: MyApp(sharedPreferences: prefs),
    ),
  );
}

Future<void> initializedDownload() async {
  await FlutterDownloader.initialize(debug: false);
}

class MyApp extends StatefulWidget {
  late SharedPreferences sharedPreferences;

  MyApp({Key? key, required this.sharedPreferences}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  setLocale(Locale locale) {
    if (mounted) {
      setState(() {
        _locale = locale;
      });
    }
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      if (mounted) {
        setState(() {
          _locale = locale;
        });
      }
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    if (_locale == null) {
      return const Center(
        child: CircularProgressIndicator(
            color: colors.primary,
            valueColor: AlwaysStoppedAnimation<Color?>(colors.primary)),
      );
    } else {
      return MultiProvider(
          providers: [
            Provider<SettingProvider>(
              create: (context) => SettingProvider(widget.sharedPreferences),
            ),
            ChangeNotifierProvider<UserProvider>(
                create: (context) => UserProvider()),
            ChangeNotifierProvider<HomeProvider>(
                create: (context) => HomeProvider()),
            ChangeNotifierProvider<CategoryProvider>(
                create: (context) => CategoryProvider()),
            ChangeNotifierProvider<ProductDetailProvider>(
                create: (context) => ProductDetailProvider()),
            ChangeNotifierProvider<FavoriteProvider>(
                create: (context) => FavoriteProvider()),
            ChangeNotifierProvider<OrderProvider>(
                create: (context) => OrderProvider()),
            ChangeNotifierProvider<CartProvider>(
                create: (context) => CartProvider()),
            ChangeNotifierProvider<ProductProvider>(
                create: (context) => ProductProvider()),
            ChangeNotifierProvider<FlashSaleProvider>(
                create: (context) => FlashSaleProvider()),
            ChangeNotifierProvider<OfferImagesProvider>(
                create: (context) => OfferImagesProvider()),
          ],
          child: MaterialApp(
            locale: _locale,
            //scaffoldMessengerKey: scaffoldMessageKey,
            supportedLocales: const [
              Locale("en", "US"),
              Locale("zh", "CN"),
              Locale("es", "ES"),
              Locale("hi", "IN"),
              Locale("ar", "DZ"),
              Locale("ru", "RU"),
              Locale("ja", "JP"),
              Locale("de", "DE")
            ],
            localizationsDelegates: const [
              CountryLocalizations.delegate,
              DemoLocalization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale!.languageCode &&
                    supportedLocale.countryCode == locale.countryCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            title: appName,
            theme: lightTheme,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => const Splash(),
              '/home': (context) => const Dashboard(),
              '/login': (context) => const Login(),
              '/new-member-registration': (context) => const MemberRegistration(),
              '/my-bonus': (context) => const MyBonus(),
              '/my-orders': (context) => const MyOrders(),
              '/my-networks': (context) => const MyNetworks(),
            },

            // darkTheme: darkTheme,

            themeMode: themeNotifier.getThemeMode(),
          ));
    }
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}