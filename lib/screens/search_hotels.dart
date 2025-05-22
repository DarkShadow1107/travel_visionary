import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class SearchHotelsScreen extends StatefulWidget {
  const SearchHotelsScreen({super.key});

  @override
  State<SearchHotelsScreen> createState() => _SearchHotelsScreenState();
}

class _SearchHotelsScreenState extends State<SearchHotelsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cityController = TextEditingController();
  String? _city;
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  int _rooms = 1;
  static const int _maxGuestsPerRoom = 3;
  List<Hotel> _hotels = [];
  List<Hotel> _filteredHotels = [];
  bool _loading = true;
  List<String> _citySuggestions = [];

  // Advanced filters for hotels
  int? _minStars;
  double? _maxHotelPrice;
  String? _selectedAmenity;
  bool _freeCancellation = false;
  List<int> get _starOptions => [1, 2, 3, 4, 5];
  List<String> get _amenities => ['Wi-Fi', 'Pool', 'Parking', 'Pet-friendly'];

  // Add hotel type filter state
  final List<String> _hotelTypes = [
    'Resort',
    'Boutique',
    'Business',
    'Budget',
    'Luxury',
    'Hostel',
  ];
  String? _selectedHotelType;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _loadHotels();
    _cityController.addListener(_onCityChanged);
  }

  Future<void> _loadHotels() async {
    final hotels = await DataService().loadHotels();
    setState(() {
      _hotels = hotels;
      _filteredHotels = hotels;
      _loading = false;
      _citySuggestions = _getUniqueCities(hotels);
    });
  }

  List<String> _getUniqueCities(List<Hotel> hotels) {
    return hotels.map((h) => h.city).toSet().toList();
  }

  void _onCityChanged() {
    setState(() {
      _city = _cityController.text;
      _citySuggestions =
          _getUniqueCities(_hotels)
              .where((c) => c.toLowerCase().contains(_city!.toLowerCase()))
              .toList();
      _filterHotels();
    });
  }

  void _showHotelFiltersSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int? tempStars = _minStars;
        double? tempPrice = _maxHotelPrice;
        String? tempAmenity = _selectedAmenity;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 40.0,
                horizontal: 32.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: tempStars,
                    decoration: const InputDecoration(
                      labelText: 'Min Stars',
                      labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                      floatingLabelStyle: TextStyle(color: Color(0xFF77B0AA)),
                      filled: true,
                      fillColor: Color(0xFF1B1A55),
                    ),
                    items:
                        [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Any'),
                          ),
                        ] +
                        _starOptions
                            .map(
                              (s) => DropdownMenuItem<int>(
                                value: s,
                                child: Text('$s★'),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => setModalState(() => tempStars = val),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempAmenity,
                    decoration: const InputDecoration(
                      labelText: 'Amenity',
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
                        _amenities
                            .map(
                              (a) => DropdownMenuItem<String>(
                                value: a,
                                child: Text(a),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => setModalState(() => tempAmenity = val),
                  ),
                  const SizedBox(height: 32),
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
                        _minStars = tempStars;
                        _maxHotelPrice = tempPrice;
                        _selectedAmenity = tempAmenity;
                        _filterHotels();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFiltersSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String? tempHotelType = _selectedHotelType;
        double? tempMaxPrice = _maxPrice;
        bool tempFreeCancellation = _freeCancellation;
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
                    value: tempHotelType,
                    decoration: const InputDecoration(
                      labelText: 'Hotel Type',
                      labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                      floatingLabelStyle: TextStyle(color: Color(0xFF77B0AA)),
                      filled: true,
                      fillColor: Color(0xFF1B1A55),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Any'),
                      ),
                      ..._hotelTypes.map(
                        (t) =>
                            DropdownMenuItem<String>(value: t, child: Text(t)),
                      ),
                    ],
                    onChanged:
                        (val) => setModalState(() => tempHotelType = val),
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
                    initialValue: tempMaxPrice?.toString() ?? '',
                    onChanged:
                        (val) => setModalState(
                          () => tempMaxPrice = double.tryParse(val),
                        ),
                  ),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    value: tempFreeCancellation,
                    onChanged:
                        (val) => setModalState(
                          () => tempFreeCancellation = val ?? false,
                        ),
                    title: const Text(
                      'Free Cancellation',
                      style: TextStyle(color: Color(0xFF77B0AA)),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Color(0xFF77B0AA),
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
                            _selectedHotelType = tempHotelType;
                            _maxPrice = tempMaxPrice;
                            _freeCancellation = tempFreeCancellation;
                            _filterHotels();
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
                            _selectedHotelType = null;
                            _maxPrice = null;
                            _freeCancellation = false;
                            _filterHotels();
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

  void _filterHotels() {
    setState(() {
      _filteredHotels =
          _hotels.where((h) {
            final matchesLocation =
                _city == null ||
                _city!.isEmpty ||
                h.city.toLowerCase().contains(_city!.toLowerCase());
            final matchesStars = _minStars == null || h.stars >= _minStars!;
            final matchesPrice =
                _maxHotelPrice == null ||
                (h.price * (_freeCancellation ? 1.06 : 1.0)) <= _maxHotelPrice!;
            final matchesAmenity =
                _selectedAmenity == null ||
                (h.amenities?.contains(_selectedAmenity) ?? true);
            final matchesHotelType =
                _selectedHotelType == null || h.type == _selectedHotelType;
            return matchesLocation &&
                matchesStars &&
                matchesPrice &&
                matchesAmenity &&
                matchesHotelType;
          }).toList();
    });
  }

  Future<void> _showDatePickerSheet({required bool isCheckOut}) async {
    DateTime initialDate =
        isCheckOut
            ? (_checkOut ?? (_checkIn ?? DateTime.now()))
            : (_checkIn ?? DateTime.now());
    DateTime firstDate =
        isCheckOut ? (_checkIn ?? DateTime.now()) : DateTime.now();
    DateTime? tempDate = isCheckOut ? _checkOut : _checkIn;
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
                        if (isCheckOut) {
                          _checkOut = tempDate;
                        } else {
                          _checkIn = tempDate;
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

  void _onGuestsChanged(int guests) {
    setState(() {
      _guests = guests;
      final minRooms = (_guests / _maxGuestsPerRoom).ceil();
      if (_rooms < minRooms) {
        _rooms = minRooms;
      }
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow main gradient to show
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1240),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find Your Perfect Hotel',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredHotels.length} results found',
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
                          width: 310,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                              floatingLabelStyle: TextStyle(
                                color: Color(0xFF77B0AA),
                              ),
                              filled: true,
                              fillColor: Color(0xFF1B1A55),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: GestureDetector(
                            onTap:
                                () => _showDatePickerSheet(isCheckOut: false),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Check-in',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF77B0AA),
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: Color(0xFF77B0AA),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1B1A55),
                                  hintText:
                                      _checkIn == null
                                          ? 'Select date'
                                          : _checkIn!
                                              .toLocal()
                                              .toString()
                                              .split(' ')[0],
                                ),
                                controller: TextEditingController(
                                  text:
                                      _checkIn == null
                                          ? ''
                                          : _checkIn!
                                              .toLocal()
                                              .toString()
                                              .split(' ')[0],
                                ),
                                readOnly: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: GestureDetector(
                            onTap: () => _showDatePickerSheet(isCheckOut: true),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Check-out',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF77B0AA),
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: Color(0xFF77B0AA),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1B1A55),
                                  hintText:
                                      _checkOut == null
                                          ? 'Select date'
                                          : _checkOut!
                                              .toLocal()
                                              .toString()
                                              .split(' ')[0],
                                ),
                                controller: TextEditingController(
                                  text:
                                      _checkOut == null
                                          ? ''
                                          : _checkOut!
                                              .toLocal()
                                              .toString()
                                              .split(' ')[0],
                                ),
                                readOnly: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<int>(
                            value: _guests,
                            decoration: const InputDecoration(
                              labelText: 'Guests',
                              labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                              floatingLabelStyle: TextStyle(
                                color: Color(0xFF77B0AA),
                              ),
                              filled: true,
                              fillColor: Color(0xFF1B1A55),
                            ),
                            items:
                                List.generate(27, (i) => i + 1)
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text('$n'),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) => _onGuestsChanged(val ?? 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<int>(
                            value: _rooms,
                            decoration: const InputDecoration(
                              labelText: 'Rooms',
                              labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                              floatingLabelStyle: TextStyle(
                                color: Color(0xFF77B0AA),
                              ),
                              filled: true,
                              fillColor: Color(0xFF1B1A55),
                            ),
                            items:
                                List.generate(
                                      9,
                                      (i) =>
                                          i +
                                          (_guests / _maxGuestsPerRoom).ceil(),
                                    )
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text('$n'),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setState(
                                  () =>
                                      _rooms =
                                          val ??
                                          (_guests / _maxGuestsPerRoom).ceil(),
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<int>(
                            value: _minStars,
                            decoration: const InputDecoration(
                              labelText: 'Stars',
                              labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                              floatingLabelStyle: TextStyle(
                                color: Color(0xFF77B0AA),
                              ),
                              filled: true,
                              fillColor: Color(0xFF1B1A55),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('Any'),
                              ),
                              ...[1, 2, 3, 4, 5].map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text('$s★'),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _minStars = val;
                                _filterHotels();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Checkbox(
                              value: _freeCancellation,
                              onChanged: (val) {
                                setState(() {
                                  _freeCancellation = val ?? false;
                                  _filterHotels();
                                });
                              },
                            ),
                            const Text('Free Cancellation'),
                          ],
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
                const SizedBox(height: 40),
                Expanded(
                  child:
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredHotels.isEmpty
                          ? const Center(child: Text('No hotels found.'))
                          : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  childAspectRatio: 1.7,
                                ),
                            itemCount: _filteredHotels.length,
                            itemBuilder: (context, i) {
                              final hotel = _filteredHotels[i];
                              // Calculate nights and total price
                              final nights =
                                  (_checkIn != null && _checkOut != null)
                                      ? _checkOut!.difference(_checkIn!).inDays
                                      : 1;
                              final pricePerNight =
                                  hotel.price *
                                  (_freeCancellation ? 1.06 : 1.0);
                              final totalPrice =
                                  pricePerNight *
                                  (nights > 0 ? nights : 1) *
                                  _rooms;
                              return InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text(
                                            hotel.name,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'City: ${hotel.city}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Country: ${hotel.country}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Row(
                                                  children: List.generate(
                                                    hotel.stars,
                                                    (index) => const Icon(
                                                      Icons.star,
                                                      color: Color(0xFF77B0AA),
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Guests: $_guests',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Rooms: $_rooms',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Check-in: ${_checkIn != null ? _checkIn!.toLocal().toString().split(' ')[0] : '-'}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Check-out: ${_checkOut != null ? _checkOut!.toLocal().toString().split(' ')[0] : '-'}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Price: \$${hotel.price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Color(
                                                  0xFF535C91,
                                                ),
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              child: const Text('Close'),
                                              onPressed:
                                                  () => Navigator.pop(context),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(
                                                  0xFF1B1A55,
                                                ),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              child: const Text('Book'),
                                              onPressed: () async {
                                                await BookingService()
                                                    .addBooking({
                                                      'type': 'hotel',
                                                      'hotelName': hotel.name,
                                                      'city': hotel.city,
                                                      'country': hotel.country,
                                                      'stars': hotel.stars,
                                                      'guests': _guests,
                                                      'rooms': _rooms,
                                                      'checkIn':
                                                          _checkIn != null
                                                              ? _checkIn!
                                                                  .toLocal()
                                                                  .toString()
                                                                  .split(' ')[0]
                                                              : '',
                                                      'checkOut':
                                                          _checkOut != null
                                                              ? _checkOut!
                                                                  .toLocal()
                                                                  .toString()
                                                                  .split(' ')[0]
                                                              : '',
                                                      'price': hotel.price,
                                                    });
                                                if (mounted) {
                                                  Navigator.pop(context);
                                                }
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Hotel booked!',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                child: Card(
                                  elevation: 8,
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  color: Color(0xFF1B1A55),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      18.0,
                                    ), // half the padding
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hotel.name,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE3FEF7),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${hotel.city}, ${hotel.country}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF77B0AA),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 1.5,
                                          ),
                                          child: Row(
                                            children: List.generate(
                                              hotel.stars,
                                              (index) => const Icon(
                                                Icons.star,
                                                color: Color(0xFF77B0AA),
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Type: ${hotel.type}',
                                          style: const TextStyle(
                                            color: Color(0xFF77B0AA),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (_freeCancellation)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Total: \$${totalPrice.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    color: Color(
                                                      0xFF80F3E7,
                                                    ), // Highlight for free cancellation
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  '($nights night${nights == 1 ? '' : 's'}, $_rooms room${_rooms == 1 ? '' : 's'})',
                                                  style: const TextStyle(
                                                    color: Color(0xFFA1C5C2),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  'Per night per room: \$${pricePerNight.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Color(0xFFA1C5C2),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const Text(
                                                  'Free Cancellation',
                                                  style: TextStyle(
                                                    color: Color(0xFFE7ABAB),
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 12,
                                                    letterSpacing: 1.1,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Total: \$${totalPrice.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF80F3E7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  '($nights night${nights == 1 ? '' : 's'}, $_rooms room${_rooms == 1 ? '' : 's'})',
                                                  style: const TextStyle(
                                                    color: Color(0xFFA1C5C2),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  'Per night per room: \$${pricePerNight.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Color(0xFFA1C5C2),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
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
