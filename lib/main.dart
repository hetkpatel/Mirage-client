import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mirageclient/login.dart';
import 'package:mirageclient/main_page.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MirageApp());
}

class MirageApp extends StatelessWidget {
  const MirageApp({super.key});
  final Color _mainColor = Colors.teal;

  @override
  Widget build(BuildContext context) {
    var colorScheme = ColorScheme.fromSeed(
      primary: _mainColor,
      seedColor: _mainColor,
    );

    return MaterialApp(
      title: 'Mirage',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        primaryColor: colorScheme.primary,
        focusColor: colorScheme.primary,
        scaffoldBackgroundColor: colorScheme.surface,
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.1),
        dialogTheme:
            DialogThemeData(backgroundColor: colorScheme.surfaceContainer),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: colorScheme.surfaceContainer,
        ),
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: GoogleFonts.overpass(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.overpass(
            color: colorScheme.primary,
            fontSize: 18,
          ),
          backgroundColor: colorScheme.surfaceContainer,
          foregroundColor: colorScheme.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(color: colorScheme.surfaceContainer),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.overpass(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          displayMedium: GoogleFonts.overpass(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          displaySmall: GoogleFonts.overpass(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            // color: colorScheme.primary,
            color: Colors.white,
          ),
          titleSmall: GoogleFonts.overpass(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            // color: colorScheme.primary,
            color: Colors.white,
          ),
          titleMedium: GoogleFonts.overpass(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            // color: colorScheme.primary,
            color: Colors.white,
          ),
          titleLarge: GoogleFonts.overpass(
            fontSize: 26.0,
            fontWeight: FontWeight.bold,
            // color: colorScheme.primary,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.black87,
          ),
        ),
        chipTheme: const ChipThemeData(
          side: BorderSide.none,
        ),
        sliderTheme: const SliderThemeData(
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
          trackHeight: 2.0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: colorScheme.surfaceContainer,
          labelTextStyle: WidgetStatePropertyAll(
            GoogleFonts.overpass(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colorScheme.primary,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colorScheme.outlineVariant,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
          ),
          labelStyle: GoogleFonts.overpass(
            color: colorScheme.primary,
          ),
          hintStyle: GoogleFonts.overpass(
            fontSize: 14.0,
            fontWeight: FontWeight.normal,
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: colorScheme.primary,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.primary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.outlineVariant,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(15)),
            ),
            labelStyle: GoogleFonts.overpass(
              color: colorScheme.primary,
            ),
            hintStyle: GoogleFonts.overpass(
              fontSize: 14.0,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
      routes: {
        '/main': (context) => const MainPage(),
      },
      home: FutureBuilder(
        future: Future.wait([
          GoogleFonts.pendingFonts([GoogleFonts.overpassTextTheme()]),
          SessionManager().get("server"),
          SessionManager().get("auth"),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final server = snapshot.data?[1] as String?;
            final auth = snapshot.data?[2] as String?;

            return Theme(
              data: Theme.of(context).copyWith(
                textTheme: GoogleFonts.overpassTextTheme(),
              ),
              child: server != null && auth != null
                  ? const MainPage()
                  : const LoginPage(),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
