import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added provider
import '../widgets/featured_card.dart';
import '../services/services.dart';
import '../models/models.dart'; // Added models for Account

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> recentSearches = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    // _loadAccountAndRecentSearches is called in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to changes in AccountService to reload searches when account changes
    // This might be better handled with a more direct notification from AccountService
    // if login/logout happens on another screen.
    // For now, we rely on didChangeDependencies being called when Provider updates.
    _loadAccountAndRecentSearches();
  }

  Future<void> _loadAccountAndRecentSearches() async {
    if (!mounted) return;
    setState(() {
      loading = true;
    });

    final accountService = Provider.of<AccountService>(context, listen: false);
    final Account? account = await accountService.getCurrentAccount();
    List<String> searches = [];

    if (account != null) {
      final bookings = account.bookings;

      bookings['flights']?.forEach((b) {
        if (b['origin'] != null && b['destination'] != null) {
          searches.add('${b['origin']} → ${b['destination']}');
        }
      });
      bookings['hotels']?.forEach((b) {
        if (b['city'] != null) {
          searches.add(b['city']);
        }
      });
      bookings['cars']?.forEach((b) {
        if (b['location'] != null) {
          searches.add(b['location']);
        }
      });
    }

    if (mounted) {
      setState(() {
        recentSearches =
            searches.toSet().toList(); // Use toSet() to get unique searches
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Potentially listen to AccountService here if more dynamic updates are needed
    // final accountService = Provider.of<AccountService>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow main gradient to show
      appBar: AppBar(
        title: const Text('Travel Visionary'),
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.notifications_none),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const CustomSearchBar(),
              // const SizedBox(height: 40),
              Text(
                'Featured Destinations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height:
                    630, // Adjusted for 25% smaller cards (0.75 * old card height for 2 rows + spacing)
                child: GridView.count(
                  crossAxisCount: 5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio:
                      1.2, // Adjusted for 25% smaller height (0.9 / 0.75)
                  // scrollDirection: Axis.horizontal, // GridView scrolls vertically by default
                  children:
                      [
                            // Replaced itemBuilder with direct children mapping
                            'Paris',
                            'Prague', // Changed from 'New York'
                            'Tokyo',
                            'Dubai',
                            'Sydney',
                            'London',
                            'Rome',
                            'Bangkok',
                            'Johannesburg', // Changed from 'Cape Town'
                            'Moscow', // Changed from 'Rio de Janeiro'
                          ]
                          .map(
                            (destination) =>
                                FeaturedCard(destination: destination),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
