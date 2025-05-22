import 'package:flutter/material.dart';
import '../services/services.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<Map<String, dynamic>> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => loading = true);
    bookings = await BookingService().getBookings();
    setState(() => loading = false);
  }

  Future<void> _clearBookings() async {
    await BookingService().clearBookings();
    await _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow main gradient to show
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Booking History',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All',
            onPressed: bookings.isEmpty ? null : _clearBookings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Bookings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${bookings.length} bookings',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : bookings.isEmpty
                  ? const Center(child: Text('No bookings yet.'))
                  : const SizedBox(height: 40),
              Expanded(
                child: ListView.separated(
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 32),
                  itemBuilder: (context, i) {
                    final b = bookings[i];
                    return Card(
                      elevation: 10,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      color: const Color(0xFF1B1A55),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              b['type'] == 'flight'
                                  ? const Icon(
                                    Icons.flight,
                                    color: Color(0xFF77B0AA),
                                    size: 32,
                                  )
                                  : null,
                          title: Text(
                            _bookingTitle(b),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE3FEF7),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _bookingSubtitle(b),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF77B0AA),
                              ),
                            ),
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
    );
  }

  String _bookingTitle(Map<String, dynamic> b) {
    switch (b['type']) {
      case 'flight':
        return '${b['origin']} → ${b['destination']}';
      case 'hotel':
        return b['hotelName'] ?? b['city'] ?? 'Hotel';
      case 'car':
        return '${b['brand']} ${b['model']}';
      default:
        return 'Booking';
    }
  }

  String _bookingSubtitle(Map<String, dynamic> b) {
    switch (b['type']) {
      case 'flight':
        return 'Carrier: ${b['carrier']}\nDate: ${b['date']}\nClass: ${b['flightClass']}\nPassengers: ${b['passengers']}';
      case 'hotel':
        return 'City: ${b['city']}\nCheck-in: ${b['checkIn']}\nCheck-out: ${b['checkOut']}\nGuests: ${b['guests']}\nRooms: ${b['rooms']}';
      case 'car':
        return 'Location: ${b['location']}\nPick-up: ${b['pickupDate']}\nReturn: ${b['returnDate']}\nPassengers: ${b['passengers']}';
      default:
        return '';
    }
  }
}
