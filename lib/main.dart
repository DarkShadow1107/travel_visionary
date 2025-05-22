import 'package:flutter/material.dart';
import 'dart:math' as math; // Added for math.pi
import 'screens/home_screen.dart';
import 'screens/search_flights.dart';
import 'screens/search_hotels.dart';
import 'screens/search_cars.dart';
import 'screens/profile_screen.dart';
import 'screens/booking_history.dart';
import 'dart:ui'; // Import for ImageFilter.blur

void main() {
  runApp(const TravelVisionaryApp());
}

class TravelVisionaryApp extends StatelessWidget {
  const TravelVisionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Visionary',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.dark, // Ensure this is Brightness.dark
          primary: Color(0xFF003C43), // deep teal
          onPrimary: Color(0xFFE3FEF7), // lightest for contrast
          secondary: Color(0xFF1B1A55), // deep blue
          onSecondary: Color(0xFFE3FEF7),
          error: Colors.red,
          onError: Color(0xFFE3FEF7),
          surface: Color(0xFF070F2B), // very dark blue
          onSurface: Color(0xFFE3FEF7),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1B1A55), // deep blue for input
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        fontFamily: 'ProductSans', // Set ProductSans as the default font
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.dark, // This is already correct
          primary: Color(0xFF003C43),
          onPrimary: Color(0xFFE3FEF7),
          secondary: Color(0xFF1B1A55),
          onSecondary: Color(0xFFE3FEF7),
          error: Colors.red,
          onError: Color(0xFFE3FEF7),
          surface: Color(0xFF070F2B),
          onSurface: Color(0xFFE3FEF7),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1B1A55),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        fontFamily: 'ProductSans', // Set ProductSans as the default font
      ),
      themeMode: ThemeMode.dark, // Forcing dark mode to ensure consistency
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  // Add SingleTickerProviderStateMixin
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchFlightsScreen(),
    const SearchHotelsScreen(),
    const SearchCarsScreen(),
    const BookingHistoryScreen(),
    const ProfileScreen(),
  ];

  late AnimationController _animationController;
  // Removed _colorAnimation

  // Define colors for the gradient
  static const Color navyColor = Color(0xFF070F2B); // Very dark blue
  static const Color brightTeal = Color(0xFF2DD4BF); // A clear, bright teal
  static const Color mediumTeal = Color(0xFF0D9488); // A medium, rich teal
  static const Color darkTransitionTeal = Color(
    0xFF003C43,
  ); // Theme's deep teal for dimming

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Updated duration
    )..repeat(); // Continuous rotation, no reverse

    // Removed _colorAnimation initialization
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Removed currentSurfaceColor variable

    return AnimatedBuilder(
      animation:
          _animationController, // Changed to _animationController for rotation
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: SweepGradient(
              // Changed to SweepGradient
              center: Alignment.center,
              colors: const [
                // New list of colors for more regions
                navyColor,
                darkTransitionTeal,
                brightTeal,
                darkTransitionTeal,
                navyColor,
                darkTransitionTeal,
                mediumTeal,
                darkTransitionTeal,
                navyColor,
                darkTransitionTeal,
                brightTeal, // Third teal region (using brightTeal again)
                darkTransitionTeal,
                navyColor,
              ],
              stops: const [
                // New list of stops for smoother transitions
                0.0, // Navy
                0.083, // DarkTransitionTeal
                0.167, // BrightTeal
                0.25, // DarkTransitionTeal
                0.333, // Navy
                0.417, // DarkTransitionTeal
                0.5, // MediumTeal
                0.583, // DarkTransitionTeal
                0.667, // Navy
                0.75, // DarkTransitionTeal
                0.833, // BrightTeal
                0.917, // DarkTransitionTeal
                1.0, // Navy
              ],
              transform: GradientRotation(
                _animationController.value * 2 * math.pi,
              ), // Rotation transform
            ),
          ),
          child: Scaffold(
            backgroundColor:
                Colors.transparent, // Make Scaffold background transparent
            body:
                _screens[_selectedIndex], // This should correctly display the selected screen
            bottomNavigationBar: Container(
              // Remove Padding, Center, and ConstrainedBox for full width
              margin: const EdgeInsets.all(
                16.0,
              ), // Keep some margin for the floating effect
              child: ClipRRect(
                // ClipRRect for rounded corners on the blurred container
                borderRadius: BorderRadius.circular(24.0), // Rounded corners
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(
                        0.65,
                      ), // Teal with opacity
                      borderRadius: BorderRadius.circular(
                        24.0,
                      ), // Ensure container also has rounded corners
                    ),
                    child: NavigationBar(
                      backgroundColor:
                          Colors
                              .transparent, // Make NavigationBar itself transparent
                      indicatorColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.5),
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (int index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.flight),
                          label: 'Flights',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.hotel),
                          label: 'Hotels',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.directions_car),
                          label: 'Cars',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.history),
                          label: 'Bookings',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
