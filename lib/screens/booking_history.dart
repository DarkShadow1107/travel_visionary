import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/services.dart';
// Import ProfileScreen

class BookingHistoryScreen extends StatefulWidget {
  // If you want to pass the account, uncomment this and the constructor
  // final Account account;
  // const BookingHistoryScreen({super.key, required this.account});
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  Account? _currentAccount;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentAccountAndBookings(); // Renamed and updated
    });
  }

  Future<void> _loadCurrentAccountAndBookings() async {
    final accountService = Provider.of<AccountService>(context, listen: false);
    final account =
        await accountService
            .getCurrentAccount(); // Use service to get current user

    if (mounted) {
      // Check if the widget is still in the widget tree
      setState(() {
        _currentAccount = account;
        _loading = false;
      });

      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to see your bookings.')),
        );
      }
    }
  }

  Future<void> _clearUserBookings() async {
    if (_currentAccount != null) {
      final accountService = Provider.of<AccountService>(
        context,
        listen: false,
      );
      await accountService.clearUserBookings(
        _currentAccount!.email,
      ); // Use new service method
      // Refresh the bookings view
      await _loadCurrentAccountAndBookings();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All bookings cleared.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get bookings directly from the _currentAccount state
    Map<String, List<Map<String, dynamic>>> userBookings =
        _currentAccount?.bookings ?? {};
    List<Map<String, dynamic>> allBookings = [];
    allBookings.addAll(userBookings['flights'] ?? []);
    allBookings.addAll(userBookings['hotels'] ?? []);
    allBookings.addAll(userBookings['cars'] ?? []);

    // Sort bookings by date (assuming a 'bookedAt' field)
    allBookings.sort((a, b) {
      DateTime? dateA = DateTime.tryParse(a['bookedAt'] ?? '');
      DateTime? dateB = DateTime.tryParse(b['bookedAt'] ?? '');
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // Put items without date at the end
      if (dateB == null) return -1; // Put items without date at the end
      return dateB.compareTo(dateA); // Sort descending (newest first)
    });

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow main gradient to show
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        toolbarHeight: 64,
        actions: [
          if (_currentAccount != null && allBookings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All My Bookings',
              onPressed: _clearUserBookings,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ), // Adjusted padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentAccount != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    bottom: 8.0,
                  ), // Match card padding
                  child: Text(
                    'Bookings for ${_currentAccount!.firstName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_currentAccount == null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text(
                        'Please log in to view your bookings.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              else if (allBookings.isEmpty)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.luggage, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'You have no bookings yet.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: allBookings.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(height: 16), // Adjusted spacing
                    itemBuilder: (context, i) {
                      final booking = allBookings[i];
                      return _buildBookingCard(booking);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    IconData iconData;
    Color iconColor;
    String title;
    List<Widget> details = [];

    switch (booking['type']) {
      case 'flight':
        iconData = Icons.flight_takeoff;
        iconColor = Colors.blueAccent;
        title =
            'Flight: ${booking['origin'] ?? 'N/A'} to ${booking['destination'] ?? 'N/A'}';
        details.add(Text('Carrier: ${booking['carrier'] ?? 'N/A'}'));
        details.add(
          Text(
            'Class: ${booking['selectedClass'] ?? 'N/A'}, Tickets: ${booking['numTickets'] ?? 'N/A'}',
          ),
        );
        details.add(
          Text('Price: \$${(booking['totalPrice'] ?? 0.0).toStringAsFixed(2)}'),
        );
        break;
      case 'hotel':
        iconData = Icons.hotel;
        iconColor = Colors.greenAccent;
        title =
            'Hotel: ${booking['name'] ?? 'N/A'} in ${booking['city'] ?? 'N/A'}';
        details.add(Text('Check-in: ${formatDate(booking['checkInDate'])}'));
        details.add(Text('Check-out: ${formatDate(booking['checkOutDate'])}'));
        details.add(
          Text(
            'Guests: ${booking['numGuests'] ?? 'N/A'}, Rooms: ${booking['numRooms'] ?? 'N/A'}',
          ),
        );
        details.add(
          Text('Price: \$${(booking['totalPrice'] ?? 0.0).toStringAsFixed(2)}'),
        );
        break;
      case 'car':
        iconData = Icons.directions_car;
        iconColor = Colors.orangeAccent;
        title =
            'Car: ${booking['brand'] ?? 'N/A'} ${booking['model'] ?? 'N/A'}';
        details.add(Text('Location: ${booking['location'] ?? 'N/A'}'));
        details.add(Text('Pickup: ${formatDate(booking['pickupDate'])}'));
        details.add(Text('Dropoff: ${formatDate(booking['dropoffDate'])}'));
        details.add(
          Text('Price: \$${(booking['totalPrice'] ?? 0.0).toStringAsFixed(2)}'),
        );
        break;
      default:
        iconData = Icons.bookmark;
        iconColor = Colors.grey;
        title = 'Unknown Booking';
        details.add(const Text('Details not available'));
    }
    if (booking['bookedAt'] != null) {
      details.add(
        Text(
          'Booked on: ${formatDate(booking['bookedAt'])}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: iconColor, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            ...details.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
}

// Helper methods in AccountService (to be added):
// Future<List<Account>> DEV_ONLY_getAllAccounts();
// Future<void> updateAccountBookings(Account account); // To save changes after clearing bookings
// Future<void> clearBookingsForUser(String email); // Alternative to above
