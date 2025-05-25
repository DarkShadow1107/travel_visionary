import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Ensured provider is imported
import '../models/models.dart';
import '../services/services.dart';

class SearchFlightsScreen extends StatefulWidget {
  const SearchFlightsScreen({super.key});

  @override
  State<SearchFlightsScreen> createState() => _SearchFlightsScreenState();
}

class _SearchFlightsScreenState extends State<SearchFlightsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _departureDateController =
      TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();
  String? _from;
  String? _to;
  DateTime? _departureDate;
  DateTime? _returnDate;
  bool _isRoundTrip = false;
  int _passengers = 1;
  String _flightClass = 'Economy';
  List<Flight> _flights = [];
  List<Flight> _filteredFlights = [];
  bool _loading = true;
  List<String> _fromSuggestions = [];
  List<String> _toSuggestions = [];

  // Advanced filters for flights
  String? _selectedAirline;
  double? _maxPrice;
  TimeOfDay? _earliestDeparture;
  TimeOfDay? _latestDeparture;
  List<String> get _airlines => _flights.map((f) => f.carrier).toSet().toList();

  @override
  void initState() {
    super.initState();
    _loadFlights();
    _fromController.addListener(_onFromChanged);
    _toController.addListener(_onToChanged);
  }

  Future<void> _loadFlights() async {
    try {
      final flights = await DataService().loadFlights();
      setState(() {
        _flights = flights;
        _filteredFlights = flights;
        _loading = false;
        _fromSuggestions = _getUniqueOrigins(flights);
        _toSuggestions = _getUniqueDestinations(flights);
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading flights.')));
    }
  }

  List<String> _getUniqueOrigins(List<Flight> flights) {
    return flights.map((f) => f.origin).toSet().toList();
  }

  List<String> _getUniqueDestinations(List<Flight> flights) {
    return flights.map((f) => f.destination).toSet().toList();
  }

  void _onFromChanged() {
    setState(() {
      _from = _fromController.text;
      _fromSuggestions =
          _getUniqueOrigins(_flights)
              .where((o) => o.toLowerCase().contains(_from!.toLowerCase()))
              .toList();
      _filterFlights();
    });
  }

  void _onToChanged() {
    setState(() {
      _to = _toController.text;
      _toSuggestions =
          _getUniqueDestinations(
            _flights,
          ).where((d) => d.toLowerCase().contains(_to!.toLowerCase())).toList();
      _filterFlights();
    });
  }

  void _showFiltersSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String? tempAirline = _selectedAirline;
        double? tempPrice = _maxPrice;
        TimeOfDay? tempEarliest = _earliestDeparture;
        TimeOfDay? tempLatest = _latestDeparture;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 48.0,
                horizontal: 36.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: tempAirline,
                    decoration: const InputDecoration(
                      labelText: 'Airline',
                      labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                      floatingLabelStyle: TextStyle(color: Color(0xFF77B0AA)),
                      filled: true,
                      fillColor: Color(0xFF1B1A55),
                    ),
                    items:
                        [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Any'),
                          ),
                        ] +
                        _airlines
                            .map(
                              (a) => DropdownMenuItem<String>(
                                value: a,
                                child: Text(a),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => setModalState(() => tempAirline = val),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Max Price',
                      labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                      floatingLabelStyle: TextStyle(color: Color(0xFF77B0AA)),
                      filled: true,
                      fillColor: Color(0xFF1B1A55),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: tempPrice?.toString() ?? '',
                    onChanged:
                        (val) => setModalState(
                          () => tempPrice = double.tryParse(val),
                        ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1B1A55),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedAirline = tempAirline;
                            _maxPrice = tempPrice;
                            _earliestDeparture = tempEarliest;
                            _latestDeparture = tempLatest;
                            _filterFlights();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Filters'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedAirline = null;
                            _maxPrice = null;
                            _earliestDeparture = null;
                            _latestDeparture = null;
                            _filterFlights();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Reset Filters'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _flightMatchesDate(Flight f, DateTime? selectedDate) {
    if (selectedDate == null) return true;
    if (f.recurrence == 'daily') return true;
    final weekday = selectedDate.weekday; // 1=Mon, 7=Sun
    final days =
        f.recurrence.split(',').map((d) => d.trim().toLowerCase()).toList();
    const dayMap = {
      'mon': 1,
      'tue': 2,
      'wed': 3,
      'thu': 4,
      'fri': 5,
      'sat': 6,
      'sun': 7,
    };
    return days.any((d) => dayMap[d] == weekday);
  }

  void _filterFlights() {
    setState(() {
      _filteredFlights =
          _flights.where((f) {
            final matchesFrom =
                _from == null ||
                _from!.isEmpty ||
                f.origin.toLowerCase().contains(_from!.toLowerCase());
            final matchesTo =
                _to == null ||
                _to!.isEmpty ||
                f.destination.toLowerCase().contains(_to!.toLowerCase());
            final matchesDate = _flightMatchesDate(f, _departureDate);
            final matchesAirline =
                _selectedAirline == null || f.carrier == _selectedAirline;

            // Updated class and price matching logic
            final matchesClass =
                _flightClass.isEmpty ||
                (f.supportedClasses.contains(_flightClass) &&
                    f.classPrices.containsKey(_flightClass) &&
                    f.classPrices[_flightClass]! > 0);

            final priceForSelectedClass = f.classPrices[_flightClass];
            final matchesPrice =
                _maxPrice == null ||
                (priceForSelectedClass != null &&
                    priceForSelectedClass <= _maxPrice!);

            final seatsAvailable =
                (f.seatsAvailable[_flightClass] != null &&
                    f.seatsAvailable[_flightClass]! >= _passengers);

            return matchesFrom &&
                matchesTo &&
                matchesDate &&
                matchesAirline &&
                matchesPrice &&
                matchesClass &&
                seatsAvailable;
          }).toList();
    });
  }

  Future<void> _showDatePickerSheet({required bool isReturn}) async {
    DateTime initialDate =
        isReturn
            ? (_returnDate ?? (_departureDate ?? DateTime.now()))
            : (_departureDate ?? DateTime.now());
    DateTime firstDate =
        isReturn ? (_departureDate ?? DateTime.now()) : DateTime.now();
    DateTime? tempDate = isReturn ? _returnDate : _departureDate;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CalendarDatePicker(
                    initialDate: tempDate ?? initialDate,
                    firstDate: firstDate,
                    lastDate: DateTime(2027, 12, 31),
                    onDateChanged: (date) {
                      setModalState(() => tempDate = date);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B1A55),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        if (isReturn) {
                          _returnDate = tempDate;
                          _returnDateController.text =
                              _returnDate != null
                                  ? _returnDate!.toLocal().toString().split(
                                    ' ',
                                  )[0]
                                  : '';
                        } else {
                          _departureDate = tempDate;
                          _departureDateController.text =
                              _departureDate != null
                                  ? _departureDate!.toLocal().toString().split(
                                    ' ',
                                  )[0]
                                  : '';
                          _filterFlights();
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper to get the correct date for display based on recurrence
  String _getDisplayDate(Flight flight) {
    if (_departureDate != null) {
      return _departureDate!.toLocal().toString().split(' ')[0];
    }
    return 'Any';
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _departureDateController.dispose();
    _returnDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow main gradient to show
      body: SafeArea(
        child: SingleChildScrollView(
          // Wrap Center with SingleChildScrollView
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 1240,
              ), // 350 + 540 + 350
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Your Perfect Flight',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_filteredFlights.length} results found',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 210,
                            child: TextFormField(
                              controller: _fromController,
                              decoration: const InputDecoration(
                                labelText: 'From',
                                labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                                floatingLabelStyle: TextStyle(
                                  color: Color(0xFF77B0AA),
                                ),
                                filled: true,
                                fillColor: Color(0xFF1B1A55),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a departure location';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  _from = val;
                                  _fromSuggestions =
                                      _getUniqueOrigins(_flights)
                                          .where(
                                            (o) => o.toLowerCase().contains(
                                              val.toLowerCase(),
                                            ),
                                          )
                                          .toList();
                                  _filterFlights();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 210,
                            child: TextFormField(
                              controller: _toController,
                              decoration: const InputDecoration(
                                labelText: 'To',
                                labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                                floatingLabelStyle: TextStyle(
                                  color: Color(0xFF77B0AA),
                                ),
                                filled: true,
                                fillColor: Color(0xFF1B1A55),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a destination';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  _to = val;
                                  _toSuggestions =
                                      _getUniqueDestinations(_flights)
                                          .where(
                                            (d) => d.toLowerCase().contains(
                                              val.toLowerCase(),
                                            ),
                                          )
                                          .toList();
                                  _filterFlights();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 150,
                            child: GestureDetector(
                              onTap:
                                  () => _showDatePickerSheet(isReturn: false),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _departureDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Departure Date',
                                    hintText: 'Select date',
                                    labelStyle: TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFF1B1A55),
                                  ),
                                  readOnly: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a departure date';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 150,
                            child: GestureDetector(
                              onTap: () => _showDatePickerSheet(isReturn: true),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _returnDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Return Date',
                                    hintText: 'Select date',
                                    labelStyle: TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFF1B1A55),
                                  ),
                                  readOnly: true,
                                  validator: (value) {
                                    if (_isRoundTrip &&
                                        (value == null || value.isEmpty)) {
                                      return 'Please select a return date';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: DropdownButtonFormField<int>(
                              value: _passengers,
                              decoration: const InputDecoration(
                                labelText: 'Passengers',
                                labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                                floatingLabelStyle: TextStyle(
                                  color: Color(0xFF77B0AA),
                                ),
                                filled: true,
                                fillColor: Color(0xFF1B1A55),
                              ),
                              items:
                                  List.generate(9, (i) => i + 1)
                                      .map(
                                        (n) => DropdownMenuItem(
                                          value: n,
                                          child: Text('$n'),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (val) =>
                                      setState(() => _passengers = val ?? 1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 200, // Reduce width to prevent overflow
                            child: DropdownButtonFormField<String>(
                              value: _flightClass,
                              decoration: const InputDecoration(
                                labelText: 'Class',
                                labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                                floatingLabelStyle: TextStyle(
                                  color: Color(0xFF77B0AA),
                                ),
                                filled: true,
                                fillColor: Color(0xFF1B1A55),
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                  left: 12,
                                  right: 16,
                                  top: 16,
                                  bottom: 16,
                                ),
                              ),
                              icon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 0,
                                  right: 0,
                                ),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF77B0AA),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Economy',
                                  child: Text('Economy'),
                                ),
                                DropdownMenuItem(
                                  value: 'Premium Economy',
                                  child: Text('Premium Economy'),
                                ),
                                DropdownMenuItem(
                                  value: 'Business',
                                  child: Text('Business'),
                                ),
                                DropdownMenuItem(
                                  value: 'First Class',
                                  child: Text('First Class'),
                                ),
                              ],
                              onChanged:
                                  (val) => setState(
                                    () => _flightClass = val ?? 'Economy',
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: Column(
                              children: [
                                Checkbox(
                                  value: _isRoundTrip,
                                  onChanged: (val) {
                                    setState(() => _isRoundTrip = val ?? false);
                                  },
                                ),
                                const Text('Round Trip'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.filter_alt,
                              color: Color(0xFF77B0AA),
                            ),
                            tooltip: 'Filters',
                            onPressed: _showFiltersSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                        // Removed Expanded widget
                        shrinkWrap: true, // Added shrinkWrap
                        physics:
                            const NeverScrollableScrollPhysics(), // Added physics
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 32,
                              mainAxisSpacing: 32,
                              childAspectRatio: 1.55,
                            ),
                        itemCount: _filteredFlights.length,
                        itemBuilder: (context, i) {
                          final flight = _filteredFlights[i];
                          // Removed showAllPrices, as we now always show the selected class price
                          return InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      backgroundColor: Color(0xFF1B1A55),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 36,
                                            vertical: 32,
                                          ),
                                      titlePadding: const EdgeInsets.fromLTRB(
                                        36,
                                        36,
                                        36,
                                        0,
                                      ),
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.flight_takeoff,
                                            color: Color(0xFF77B0AA),
                                            size: 32,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${flight.origin} → ${flight.destination}',
                                            style: const TextStyle(
                                              color: Color(0xFFE3FEF7),
                                              fontSize: 22,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Carrier: ${flight.carrier}',
                                            style: const TextStyle(
                                              color: Color(0xFFE3FEF7),
                                              fontSize: 18,
                                            ),
                                          ),
                                          Text(
                                            'Departure: ${_getDisplayDate(flight)} ${flight.departureTime}',
                                            style: const TextStyle(
                                              color: Color(0xFF77B0AA),
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Arrival: ${flight.arrivalTime}',
                                            style: const TextStyle(
                                              color: Color(0xFF77B0AA),
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Aircraft: ${flight.aircraft.contains('Boeing 787') && !flight.aircraft.contains('Dreamliner') ? '${flight.aircraft} Dreamliner' : flight.aircraft}',
                                            style: const TextStyle(
                                              color: Color(0xFF77B0AA),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Classes: ${flight.supportedClasses.join(", ")}',
                                            style: const TextStyle(
                                              color: Color(0xFFE3FEF7),
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Flight Time: ${flight.formattedFlightDuration}',
                                            style: const TextStyle(
                                              color: Color(0xFFE3FEF7),
                                              fontSize: 16,
                                            ),
                                          ),
                                          // Display only the price for the selected class
                                          if (flight.classPrices.containsKey(
                                                _flightClass,
                                              ) &&
                                              flight.classPrices[_flightClass]! >
                                                  0)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Price: \$${((flight.classPrices[_flightClass] ?? 0) * _passengers).toStringAsFixed(2)} ($_passengers passengers, $_flightClass)',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFE3FEF7),
                                                  ),
                                                ),
                                                if (_passengers > 1)
                                                  Text(
                                                    '(\$${flight.classPrices[_flightClass]?.toStringAsFixed(2) ?? '-'} per person)',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFFE3FEF7),
                                                    ),
                                                  ),
                                              ],
                                            )
                                          else
                                            Text(
                                              'Price not available for $_flightClass',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                      actionsPadding: const EdgeInsets.fromLTRB(
                                        36,
                                        0,
                                        36,
                                        24,
                                      ),
                                      actions: [
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Color(0xFF77B0AA),
                                          ),
                                          child: const Text('Close'),
                                          onPressed:
                                              () => Navigator.pop(context),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF003C43),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Book'),
                                          onPressed: () async {
                                            // Made onPressed async
                                            final accountService =
                                                Provider.of<AccountService>(
                                                  context,
                                                  listen: false,
                                                );
                                            final Account? account =
                                                await accountService
                                                    .getCurrentAccount();

                                            if (account == null) {
                                              Navigator.of(
                                                context,
                                              ).pop(); // Close dialog
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'You must be logged in to book a flight.',
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                              );
                                              return;
                                            }

                                            // Ensure _departureDate is not null before proceeding
                                            if (_departureDate == null) {
                                              Navigator.of(
                                                context,
                                              ).pop(); // Close dialog
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please select a departure date first.',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orangeAccent,
                                                ),
                                              );
                                              return;
                                            }

                                            // Corrected parameters for addFlightBooking
                                            await accountService.addFlightBooking(
                                              flight, // Flight object
                                              _flightClass, // String selectedClass
                                              _passengers, // int numTickets
                                              // _departureDate and _returnDate are not direct params for this service method
                                              // The service method itself uses DateTime.now() for bookedAt
                                              // and flight details for dates if needed by the model structure.
                                              // If departure/return dates need to be part of the *booking record* itself,
                                              // then the addFlightBooking method in AccountService and the Flight booking map needs adjustment.
                                              // For now, assuming the service handles date logic based on the Flight object and internal logic.
                                            );
                                            if (mounted) {
                                              Navigator.pop(
                                                context,
                                              ); // Close dialog
                                            }
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Flight booked!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: Card(
                              elevation: 10,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              color: Color(0xFF1B1A55),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 16.0,
                                  left: 24.0,
                                  right: 24.0,
                                  bottom: 24.0,
                                ), // Adjust top padding
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .start, // Align children to the start (top)
                                  children: [
                                    if (flight.carrierLogo != null &&
                                        flight.carrierLogo!.isNotEmpty)
                                      Container(
                                        width:
                                            180, // Increased width for the container
                                        height:
                                            60, // Increased height for the container
                                        padding: const EdgeInsets.all(8.0),
                                        margin: const EdgeInsets.only(
                                          bottom: 18.0,
                                        ), // Increased bottom margin
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFFFFFFF,
                                          ), // White background
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                        ),
                                        child: Image.asset(
                                          flight.carrierLogo!,
                                          // height: 35, // Remove fixed height from Image.asset
                                          // width: 100, // Remove fixed width from Image.asset
                                          fit:
                                              BoxFit
                                                  .contain, // BoxFit.contain will scale down if needed, maintaining aspect ratio
                                          alignment: Alignment.centerLeft,
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            flight.origin,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE3FEF7),
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.flight_takeoff,
                                          color: Color(0xFF77B0AA),
                                          size: 28,
                                        ),
                                        Expanded(
                                          child: Text(
                                            flight.destination,
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE3FEF7),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Departure: ${_getDisplayDate(flight)} ${flight.departureTime}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF77B0AA),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Arrival: ${flight.arrivalTime}',
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF77B0AA),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Carrier: ${flight.carrier}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFFE3FEF7),
                                      ),
                                    ),
                                    Text(
                                      'Aircraft: ${flight.aircraft.contains('Boeing 787') && !flight.aircraft.contains('Dreamliner') ? '${flight.aircraft} Dreamliner' : flight.aircraft}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF77B0AA),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Classes: ${flight.supportedClasses.join(", ")}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFFE3FEF7),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Flight Time: ${flight.formattedFlightDuration}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFFE3FEF7),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Display only the price for the selected class
                                    if (flight.classPrices.containsKey(
                                          _flightClass,
                                        ) &&
                                        flight.classPrices[_flightClass]! > 0)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Price: \$${((flight.classPrices[_flightClass] ?? 0) * _passengers).toStringAsFixed(2)} ($_passengers passengers, $_flightClass)',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE3FEF7),
                                            ),
                                          ),
                                          if (_passengers > 1)
                                            Text(
                                              '(\$${flight.classPrices[_flightClass]?.toStringAsFixed(2) ?? '-'} per person)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFFE3FEF7),
                                              ),
                                            ),
                                        ],
                                      )
                                    else
                                      Text(
                                        'Price not available for $_flightClass',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
