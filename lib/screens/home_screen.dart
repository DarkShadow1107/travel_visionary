import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import '../widgets/featured_card.dart';
import '../services/services.dart';

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
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final bookings = await BookingService().getBookings();
    setState(() {
      recentSearches =
          bookings
              .map(
                (b) =>
                    b['type'] == 'flight'
                        ? '${b['origin']} → ${b['destination']}'
                        : b['type'] == 'hotel'
                        ? b['city']
                        : b['location'],
              )
              .toSet()
              .toList()
              .cast<String>();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Allow main gradient to show
        appBar: AppBar(
          title: const Text('Travel Visionary'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomSearchBar(),
                const SizedBox(height: 40),
                Text(
                  'Featured Destinations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final destinations = [
                        'Paris',
                        'New York',
                        'Tokyo',
                        'Dubai',
                        'Sydney',
                        'London',
                        'Rome',
                        'Bangkok',
                        'Cape Town',
                        'Rio de Janeiro',
                      ];
                      return FeaturedCard(destination: destinations[index]);
                    },
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Recent Searches',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child:
                      loading
                          ? const Center(child: CircularProgressIndicator())
                          : recentSearches.isEmpty
                          ? const Text('No recent searches.')
                          : ListView.separated(
                            itemCount: recentSearches.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 32),
                            itemBuilder: (context, i) {
                              final search = recentSearches[i];
                              return Card(
                                elevation: 10,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                color: Theme.of(context).colorScheme.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    search,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE3FEF7),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
