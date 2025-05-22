import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class SearchCarsScreen extends StatefulWidget {
  const SearchCarsScreen({super.key});

  @override
  State<SearchCarsScreen> createState() => _SearchCarsScreenState();
}

class _SearchCarsScreenState extends State<SearchCarsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  String? _location;
  DateTime? _pickupDate;
  DateTime? _dropoffDate;
  int _passengers = 1;
  List<Car> _cars = [];
  List<Car> _filteredCars = [];
  bool _loading = true;

  // Advanced filters for cars - to be added in the modal
  String? _selectedBrand;
  String? _selectedFuelType;
  int? _minYear;
  int? _maxYear;
  String? _selectedTransmission;
  String?
  _selectedCarType; // Already exists, can be moved to advanced or kept in main

  // Options for filters - these would be populated from data or defined statically
  List<String> _carBrands = []; // e.g., ['Toyota', 'Honda', 'BMW']
  List<String> _fuelTypes = ['Gasoline', 'Diesel', 'Electric', 'Hybrid'];
  List<String> _transmissionTypes = ['Automatic', 'Manual'];
  List<String> _carTypes = [
    'Sedan',
    'SUV',
    'Truck',
    'Van',
    'Coupe',
    'Hatchback',
  ];

  @override
  void initState() {
    super.initState();
    _loadCars();
    _locationController.addListener(_onLocationChanged);
  }

  Future<void> _loadCars() async {
    final cars =
        await DataService()
            .loadCars(); // Assuming DataService().loadCars() exists
    setState(() {
      _cars = cars;
      _filteredCars = cars;
      _loading = false;
      // Populate filter options from loaded data if necessary
      _carBrands = cars.map((c) => c.brand).toSet().toList();
      // _carTypes = cars.map((c) => c.type ?? 'Unknown').toSet().toList(); // If type is nullable
    });
  }

  void _onLocationChanged() {
    setState(() {
      _location = _locationController.text;
      _filterCars();
    });
  }

  void _filterCars() {
    setState(() {
      _filteredCars =
          _cars.where((car) {
            final matchesLocation =
                _location == null ||
                _location!.isEmpty ||
                car.location.toLowerCase().contains(_location!.toLowerCase());
            // Add other main form filter conditions here (dates, passengers)
            // Advanced filter conditions will be added later
            final matchesCarType =
                _selectedCarType == null || car.type == _selectedCarType;

            // Advanced Filters (will be expanded)
            final matchesBrand =
                _selectedBrand == null || car.brand == _selectedBrand;
            final matchesFuelType =
                _selectedFuelType == null || car.fuelType == _selectedFuelType;
            final matchesMinYear = _minYear == null || car.year >= _minYear!;
            final matchesMaxYear = _maxYear == null || car.year <= _maxYear!;
            final matchesTransmission =
                _selectedTransmission == null ||
                car.transmission == _selectedTransmission;

            return matchesLocation &&
                matchesCarType &&
                matchesBrand &&
                matchesFuelType &&
                matchesMinYear &&
                matchesMaxYear &&
                matchesTransmission;
          }).toList();
    });
  }

  Future<void> _showDatePickerSheet({required bool isDropoff}) async {
    DateTime initialDate =
        isDropoff
            ? (_dropoffDate ?? (_pickupDate ?? DateTime.now()))
            : (_pickupDate ?? DateTime.now());
    DateTime firstDate =
        isDropoff ? (_pickupDate ?? DateTime.now()) : DateTime.now();
    DateTime? tempDate = isDropoff ? _dropoffDate : _pickupDate;

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
                    lastDate: DateTime(
                      DateTime.now().year + 5,
                      12,
                      31,
                    ), // 5 years in future
                    onDateChanged: (date) {
                      setModalState(() => tempDate = date);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1A55),
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
                        if (isDropoff) {
                          _dropoffDate = tempDate;
                        } else {
                          _pickupDate = tempDate;
                          // Ensure dropoff date is after pickup date
                          if (_dropoffDate != null &&
                              _pickupDate != null &&
                              _dropoffDate!.isBefore(_pickupDate!)) {
                            _dropoffDate = _pickupDate!.add(
                              const Duration(days: 1),
                            );
                          }
                        }
                        _filterCars();
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

  // Placeholder for the advanced filters modal
  void _showCarFiltersSheet() async {
    // Temporary state for the modal sheet
    String? tempBrand = _selectedBrand;
    String? tempFuelType = _selectedFuelType;
    int? tempMinYear = _minYear;
    int? tempMaxYear = _maxYear;
    String? tempTransmission = _selectedTransmission;
    String? tempCarType = _selectedCarType; // Added for car type in modal

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Crucial for taller modal
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24.0,
                left: 32.0,
                right: 32.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ), // Padding for keyboard
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height *
                      0.85, // Increased height
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Advanced Car Filters",
                        style: TextStyle(
                          fontSize: 22, // Slightly larger title
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF77B0AA),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Car Type Dropdown
                      DropdownButtonFormField<String?>(
                        value: tempCarType,
                        style: const TextStyle(color: Color(0xFFE3FEF7)),
                        dropdownColor: const Color(0xFF070F2B),
                        decoration: const InputDecoration(
                          labelText: 'Car Type',
                          labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                          floatingLabelStyle: TextStyle(
                            color: Color(0xFF77B0AA),
                          ),
                          filled: true,
                          fillColor: Color(0xFF1B1A55),
                          prefixIcon: Icon(
                            Icons.directions_car,
                            color: Color(0xFF77B0AA),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Any Type'),
                          ),
                          ..._carTypes.map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          ),
                        ],
                        onChanged:
                            (val) => setModalState(() => tempCarType = val),
                      ),
                      const SizedBox(height: 16),
                      // Brand Dropdown
                      DropdownButtonFormField<String>(
                        value: tempBrand,
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                          filled: true,
                          fillColor: Color(0xFF1B1A55),
                        ),
                        items:
                            [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Any Brand'),
                              ),
                            ] +
                            _carBrands
                                .map(
                                  (brand) => DropdownMenuItem(
                                    value: brand,
                                    child: Text(brand),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setModalState(() => tempBrand = val),
                      ),
                      const SizedBox(height: 16),
                      // Fuel Type Dropdown
                      DropdownButtonFormField<String?>(
                        value: tempFuelType,
                        style: const TextStyle(color: Color(0xFFE3FEF7)),
                        dropdownColor: const Color(0xFF070F2B),
                        decoration: const InputDecoration(
                          labelText: 'Fuel Type',
                          labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                          floatingLabelStyle: TextStyle(
                            color: Color(0xFF77B0AA),
                          ),
                          filled: true,
                          fillColor: Color(0xFF1B1A55),
                          prefixIcon: Icon(
                            Icons.local_gas_station, // Relevant icon
                            color: Color(0xFF77B0AA),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Any Fuel'),
                          ),
                          ..._fuelTypes.map(
                            (fuel) => DropdownMenuItem(
                              value: fuel,
                              child: Text(fuel),
                            ),
                          ),
                        ],
                        onChanged:
                            (val) => setModalState(() => tempFuelType = val),
                      ),
                      const SizedBox(height: 16),
                      // Min Year TextFormField
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Min Year (e.g., 2015)',
                          labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                          filled: true,
                          fillColor: Color(0xFF1B1A55),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: tempMinYear?.toString() ?? '',
                        onChanged:
                            (val) => setModalState(
                              () => tempMinYear = int.tryParse(val),
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Max Year TextFormField
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Max Year (e.g., 2023)',
                          labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                          filled: true,
                          fillColor: Color(0xFF1B1A55),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: tempMaxYear?.toString() ?? '',
                        onChanged:
                            (val) => setModalState(
                              () => tempMaxYear = int.tryParse(val),
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Transmission Dropdown
                      DropdownButtonFormField<String?>(
                        value: tempTransmission,
                        style: const TextStyle(color: Color(0xFFE3FEF7)),
                        dropdownColor: const Color(0xFF070F2B),
                        decoration: const InputDecoration(
                          labelText: 'Transmission',
                          labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                          floatingLabelStyle: TextStyle(
                            color: Color(0xFF77B0AA),
                          ),
                          filled: true,
                          fillColor: Color(0xFF1B1A55),
                          prefixIcon: Icon(
                            Icons.settings_input_component, // Relevant icon
                            color: Color(0xFF77B0AA),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Any Transmission'),
                          ),
                          ..._transmissionTypes.map(
                            (trans) => DropdownMenuItem(
                              value: trans,
                              child: Text(trans),
                            ),
                          ),
                        ],
                        onChanged:
                            (val) =>
                                setModalState(() => tempTransmission = val),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF77B0AA,
                              ), // Primary action color
                              foregroundColor: const Color(
                                0xFF070F2B,
                              ), // Dark text for contrast
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ), // Increased padding
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedBrand = tempBrand;
                                _selectedFuelType = tempFuelType;
                                _minYear = tempMinYear;
                                _maxYear = tempMaxYear;
                                _selectedTransmission = tempTransmission;
                                _selectedCarType =
                                    tempCarType; // Apply car type
                                _filterCars();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Apply Filters'),
                          ),
                          TextButton(
                            // Changed Reset to TextButton for less emphasis
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[400], // Softer color
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600, // Slightly bolder
                                fontSize: 15,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedBrand = null;
                                _selectedFuelType = null;
                                _minYear = null;
                                _maxYear = null;
                                _selectedTransmission = null;
                                _selectedCarType = null; // Reset car type
                                _filterCars();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Reset All'),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ), // Ensure some space at the bottom
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow main gradient to show
      body: SafeArea(
        child: SingleChildScrollView(
          // Ensures the whole page is scrollable
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1240),
              padding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 16,
              ), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Your Perfect Ride',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_filteredCars.length} results found',
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
                          // Location
                          SizedBox(
                            width: 320, // Adjusted width
                            child: TextFormField(
                              controller: _locationController,
                              style: const TextStyle(color: Color(0xFFE3FEF7)),
                              decoration: const InputDecoration(
                                labelText: 'Location',
                                labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                                floatingLabelStyle: TextStyle(
                                  color: Color(0xFF77B0AA),
                                ),
                                filled: true,
                                fillColor: Color(0xFF1B1A55),
                                prefixIcon: Icon(
                                  Icons.location_on,
                                  color: Color(0xFF77B0AA),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Pick-up Date
                          SizedBox(
                            width: 220, // Adjusted width
                            child: GestureDetector(
                              onTap:
                                  () => _showDatePickerSheet(isDropoff: false),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  style: const TextStyle(
                                    color: Color(0xFFE3FEF7),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Pick-up Date',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                    floatingLabelStyle: const TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1B1A55),
                                    prefixIcon: const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF77B0AA),
                                    ),
                                    hintText:
                                        _pickupDate == null
                                            ? 'Select date'
                                            : _pickupDate!
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0],
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text:
                                        _pickupDate == null
                                            ? ''
                                            : _pickupDate!
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
                          // Drop-off Date
                          SizedBox(
                            width: 220, // Adjusted width
                            child: GestureDetector(
                              onTap:
                                  () => _showDatePickerSheet(isDropoff: true),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  style: const TextStyle(
                                    color: Color(0xFFE3FEF7),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Drop-off Date',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                    floatingLabelStyle: const TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1B1A55),
                                    prefixIcon: const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF77B0AA),
                                    ),
                                    hintText:
                                        _dropoffDate == null
                                            ? 'Select date'
                                            : _dropoffDate!
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0],
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF77B0AA),
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text:
                                        _dropoffDate == null
                                            ? ''
                                            : _dropoffDate!
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
                          // Passengers
                          SizedBox(
                            width: 180, // Adjusted width
                            child: DropdownButtonFormField<int>(
                              value: _passengers,
                              style: const TextStyle(color: Color(0xFFE3FEF7)),
                              dropdownColor: const Color(0xFF070F2B),
                              decoration: const InputDecoration(
                                labelText: 'Passengers',
                                labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                                floatingLabelStyle: TextStyle(
                                  color: Color(0xFF77B0AA),
                                ),
                                filled: true,
                                fillColor: Color(0xFF1B1A55),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Color(0xFF77B0AA),
                                ),
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
                              onChanged: (val) {
                                setState(() {
                                  _passengers = val ?? 1;
                                  _filterCars();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Car Type Dropdown in main form
                          SizedBox(
                            width: 200, // Adjusted width
                            child: DropdownButtonFormField<String?>(
                              value: _selectedCarType,
                              style: const TextStyle(color: Color(0xFFE3FEF7)),
                              dropdownColor: const Color(0xFF070F2B),
                              decoration: const InputDecoration(
                                labelText: 'Car Type',
                                labelStyle: TextStyle(color: Color(0xFF77B0AA)),
                                floatingLabelStyle: TextStyle(
                                  color: Color(0xFF77B0AA),
                                ),
                                filled: true,
                                fillColor: Color(0xFF1B1A55),
                                prefixIcon: Icon(
                                  Icons.directions_car,
                                  color: Color(0xFF77B0AA),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Any Type'),
                                ),
                                ..._carTypes.map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedCarType = val;
                                  _filterCars();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Filters Button
                          IconButton(
                            icon: const Icon(
                              Icons.filter_alt,
                              size: 30, // Slightly larger icon
                              color: Color(0xFF77B0AA),
                            ),
                            tooltip: 'Advanced Filters',
                            onPressed: _showCarFiltersSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredCars.isEmpty
                      ? const Center(
                        child: Text('No cars found matching your criteria.'),
                      )
                      : GridView.builder(
                        shrinkWrap: true, // Important for SingleChildScrollView
                        physics:
                            const NeverScrollableScrollPhysics(), // Important for SingleChildScrollView
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  3, // Adjust as needed, maybe 2 or 3 for cars
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio:
                                  1.05, // Adjusted: Made cards shorter. Original was 0.75 (taller).
                            ),
                        itemCount: _filteredCars.length,
                        itemBuilder: (context, i) {
                          final car = _filteredCars[i];

                          return InkWell(
                            onTap: () {
                              print(
                                'DEBUG: Car card tapped. Model: ${car.model}',
                              ); // For tracing
                              showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      print(
                                        'DEBUG: AlertDialog builder started.',
                                      ); // For tracing
                                      try {
                                        final int rentalDays =
                                            (_dropoffDate != null &&
                                                    _pickupDate != null)
                                                ? _dropoffDate!
                                                        .difference(
                                                          _pickupDate!,
                                                        )
                                                        .inDays
                                                        .abs() +
                                                    1
                                                : 1;
                                        final double totalPrice =
                                            rentalDays * car.price;
                                        final String carImage =
                                            car.image.startsWith(
                                                  'assets/assets/',
                                                )
                                                ? car.image.replaceFirst(
                                                  'assets/assets/',
                                                  'assets/',
                                                )
                                                : car.image;

                                        final alert = AlertDialog(
                                          backgroundColor: Theme.of(
                                            dialogContext,
                                          ).colorScheme.surface.withOpacity(
                                            0.98,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          title: Text(
                                            '${car.brand} ${car.model}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF80F3E7),
                                              fontSize: 22,
                                            ),
                                          ),
                                          content: SingleChildScrollView(
                                            child: ListBody(
                                              children: <Widget>[
                                                Center(
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.0,
                                                        ),
                                                    child: Image.asset(
                                                      carImage,
                                                      height: 180,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        print(
                                                          'DEBUG: Error loading image $carImage: $error',
                                                        );
                                                        return Container(
                                                          height: 180,
                                                          color:
                                                              Colors.grey[300],
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            size: 60,
                                                            color:
                                                                Colors
                                                                    .grey[600],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                _buildDetailRowDialog(
                                                  title: 'Location',
                                                  value: car.location,
                                                  context: dialogContext,
                                                  icon: Icons.location_on,
                                                ),
                                                _buildDetailRowDialog(
                                                  title: 'Price/Day',
                                                  value:
                                                      '\\${car.price.toStringAsFixed(2)}',
                                                  context: dialogContext,
                                                  icon: Icons.monetization_on,
                                                ),
                                                _buildDetailRowDialog(
                                                  title: 'Year',
                                                  value: car.year.toString(),
                                                  context: dialogContext,
                                                  icon: Icons.calendar_today,
                                                ),
                                                if (car.seats != null)
                                                  _buildDetailRowDialog(
                                                    title: 'Seats',
                                                    value: '${car.seats} Seats',
                                                    context: dialogContext,
                                                    icon:
                                                        Icons
                                                            .airline_seat_recline_normal,
                                                  ),
                                                _buildDetailRowDialog(
                                                  title: 'Fuel Type',
                                                  value: car.fuelType,
                                                  context: dialogContext,
                                                  icon: Icons.local_gas_station,
                                                ),
                                                _buildDetailRowDialog(
                                                  title: 'Transmission',
                                                  value: car.transmission,
                                                  context: dialogContext,
                                                  icon:
                                                      Icons
                                                          .settings_input_component,
                                                ),
                                                if (car.type != null)
                                                  _buildDetailRowDialog(
                                                    title: 'Type',
                                                    value: car.type!,
                                                    context: dialogContext,
                                                    icon: Icons.directions_car,
                                                  ),
                                                if (car.mileage != null)
                                                  _buildDetailRowDialog(
                                                    title: 'Mileage',
                                                    value: '${car.mileage} km',
                                                    context: dialogContext,
                                                    icon: Icons.speed,
                                                  ),
                                                if (car.engineSize != null)
                                                  _buildDetailRowDialog(
                                                    title: 'Engine',
                                                    value: '${car.engineSize}L',
                                                    context: dialogContext,
                                                    icon: Icons.engineering,
                                                  ),
                                                if (car.color != null)
                                                  _buildDetailRowDialog(
                                                    title: 'Color',
                                                    value: car.color!,
                                                    context: dialogContext,
                                                    icon: Icons.color_lens,
                                                  ),
                                                const Divider(
                                                  height: 24,
                                                  thickness: 1,
                                                ),
                                                _buildDetailRowDialog(
                                                  title: 'Rental Days',
                                                  value: '$rentalDays day(s)',
                                                  context: dialogContext,
                                                  icon: Icons.date_range,
                                                ),
                                                _buildDetailRowDialog(
                                                  title: 'Total Price',
                                                  value:
                                                      '\\${totalPrice.toStringAsFixed(2)}',
                                                  context: dialogContext,
                                                  icon: Icons.attach_money,
                                                ),
                                              ],
                                            ),
                                          ),
                                          actionsAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          actionsPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 12.0,
                                              ),
                                          actions: <Widget>[
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.grey[600],
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              child: const Text('Close'),
                                              onPressed: () {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();
                                              },
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
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
                                              child: const Text('Book Now'),
                                              onPressed: () {
                                                if (_pickupDate == null ||
                                                    _dropoffDate == null) {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop(); // Close the current dialog first
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Please select pickup and dropoff dates first.',
                                                      ),
                                                      backgroundColor:
                                                          Colors.orangeAccent,
                                                    ),
                                                  );
                                                  return;
                                                }
                                                // Corrected: Ensure rentalDays is positive for BookingService
                                                final int currentRentalDays =
                                                    _dropoffDate!
                                                        .difference(
                                                          _pickupDate!,
                                                        )
                                                        .inDays
                                                        .abs() +
                                                    1;
                                                if (currentRentalDays <= 0) {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Dropoff date must be after pickup date.',
                                                      ),
                                                      backgroundColor:
                                                          Colors.orangeAccent,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                BookingService().bookCar(
                                                  car,
                                                  _pickupDate!,
                                                  _dropoffDate!,
                                                );
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${car.brand} ${car.model} booked!',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                        print(
                                          'DEBUG: AlertDialog instance created. Returning dialog.',
                                        ); // For tracing
                                        return alert;
                                      } catch (e, s) {
                                        print(
                                          'DEBUG: Exception in AlertDialog builder: $e',
                                        );
                                        print(
                                          'DEBUG: Stack trace for AlertDialog builder: $s',
                                        );
                                        // Return a simple error dialog
                                        return AlertDialog(
                                          title: const Text('Error'),
                                          content: Text(
                                            'Could not display car details: $e',
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text('Close'),
                                              onPressed: () {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  )
                                  .then((value) {
                                    print(
                                      'DEBUG: Dialog closed with value: $value',
                                    ); // For tracing
                                  })
                                  .catchError((error, stackTrace) {
                                    print(
                                      'DEBUG: Error after showDialog (e.g. if builder itself throws before returning future): $error',
                                    );
                                    print(
                                      'DEBUG: Stack trace for showDialog error: $stackTrace',
                                    );
                                  });
                            },
                            child: Card(
                              elevation: 6, // Adjusted elevation
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              color: const Color(
                                0xFF1B1A55,
                              ), // Hotel card color
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  16.0,
                                ), // Adjusted padding
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AspectRatio(
                                      // For consistent image height
                                      aspectRatio: 16 / 9,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ), // Rounded corners for image
                                        child: Image.asset(
                                          car.image.startsWith('assets/assets/')
                                              ? car.image.replaceFirst(
                                                'assets/assets/',
                                                'assets/',
                                              )
                                              : car.image,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.directions_car,
                                                    size: 50,
                                                    color: Color(0xFF77B0AA),
                                                  ), // Placeholder
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${car.brand} ${car.model}',
                                      style: const TextStyle(
                                        fontSize: 17, // Slightly larger
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE3FEF7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      car.location,
                                      style: const TextStyle(
                                        fontSize: 13, // Adjusted size
                                        color: Color(0xFF77B0AA),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      // Combined type and year
                                      '${car.type ?? 'N/A'} - ${car.year}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFE3FEF7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      // Fuel and transmission
                                      '${car.fuelType} - ${car.transmission}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFE3FEF7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Align(
                                      // Align price to the right
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '\$${car.price.toStringAsFixed(2)}/day',
                                        style: const TextStyle(
                                          fontSize: 15, // Larger price
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE3FEF7),
                                        ),
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

// Helper function to build detail rows for the dialog, now expecting named parameters and icon
Widget _buildDetailRowDialog({
  required String title,
  required String value,
  required BuildContext context,
  IconData? icon,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0), // Adjusted padding
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF80F3E7),
          ), // Use theme color
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2, // Give more space to title
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600, // Bolder title
              fontSize: 15,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.8), // Slightly muted
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3, // Give more space to value
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}

/* Commented out as it seems unused and was causing confusion. Can be removed if not needed.
Widget _buildDetailRow(String title, String value, {IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      vertical: 4.0,
    ), // Increased vertical padding
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 15, // Consistent font size
            fontWeight: FontWeight.w600, // Bolder title
            color: Color(0xFF77B0AA), // Themed color for title
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15, // Consistent font size
              color: Color(0xFFE3FEF7), // Main text color
            ),
          ),
        ),
      ],
    ),
  );
}
*/
