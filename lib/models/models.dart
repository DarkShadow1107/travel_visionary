// Data models for flights, hotels, cars, bookings, and user profile will be added here.
// Example:
class Flight {
  final String id;
  final String origin;
  final String destination;
  final String carrier;
  final String? carrierLogo; // Added for airline logo
  final String recurrence;
  final String departureTime;
  final String arrivalTime;
  final String flightDuration;
  final Map<String, double> classPrices;
  final List<String> supportedClasses;
  final String aircraft;
  final Map<String, int> seatsAvailable;
  final String? date; // e.g. '2023-10-10'
  final List<FlightSegment>? segments;

  Flight({
    required this.id,
    required this.origin,
    required this.destination,
    required this.carrier,
    this.carrierLogo, // Added
    required this.recurrence,
    required this.departureTime,
    required this.arrivalTime,
    required this.flightDuration,
    required this.classPrices,
    required this.supportedClasses,
    required this.aircraft,
    required this.seatsAvailable,
    this.date,
    this.segments,
  });

  factory Flight.fromJson(Map<String, dynamic> json) => Flight(
    id: json['id'],
    origin: json['origin'],
    destination: json['destination'],
    carrier: json['carrier'],
    carrierLogo: json['carrierLogo'], // Added
    recurrence: json['recurrence'],
    departureTime: json['departure_time'],
    arrivalTime: json['arrival_time'],
    flightDuration: json['flightDuration'],
    classPrices: (json['classPrices'] as Map).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ),
    supportedClasses:
        (json['supportedClasses'] as List).map((e) => e.toString()).toList(),
    aircraft: json['aircraft'],
    seatsAvailable: (json['seatsAvailable'] as Map).map(
      (k, v) => MapEntry(k.toString(), int.parse(v.toString())),
    ),
    date: json['date'],
    segments:
        json['segments'] != null
            ? (json['segments'] as List)
                .map((s) => FlightSegment.fromJson(s))
                .toList()
            : null,
  );

  double get price =>
      classPrices.isNotEmpty
          ? classPrices.values.reduce((a, b) => a < b ? a : b)
          : 0.0;

  static Duration parseDuration(String durationStr) {
    final parts = durationStr.split(':');
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return Duration(hours: hours, minutes: minutes);
  }

  String get formattedFlightDuration {
    final d = parseDuration(flightDuration);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class FlightSegment {
  final String origin;
  final String destination;
  final String carrier;
  final String departureTime;
  final String arrivalTime;
  final String aircraft;
  final List<String> supportedClasses;
  final Map<String, int>? seatsAvailable;
  final int? layoverMinutes; // null for last segment

  FlightSegment({
    required this.origin,
    required this.destination,
    required this.carrier,
    required this.departureTime,
    required this.arrivalTime,
    required this.aircraft,
    required this.supportedClasses,
    this.seatsAvailable,
    this.layoverMinutes,
  });

  factory FlightSegment.fromJson(Map<String, dynamic> json) => FlightSegment(
    origin: json['origin'],
    destination: json['destination'],
    carrier: json['carrier'],
    departureTime: json['departure_time'],
    arrivalTime: json['arrival_time'],
    aircraft: json['aircraft'],
    supportedClasses:
        (json['supportedClasses'] as List).map((e) => e.toString()).toList(),
    seatsAvailable: (json['seatsAvailable'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), int.parse(v.toString())),
    ),
    layoverMinutes: json['layoverMinutes'],
  );
}

class Hotel {
  final String id;
  final String name;
  final String city;
  final String country;
  final int stars;
  final double price;
  final String image;
  final List<String>? amenities;
  final String type; // e.g. 'Resort', 'Boutique', etc.

  Hotel({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.stars,
    required this.price,
    required this.image,
    this.amenities,
    this.type = 'Resort',
  });

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    country: json['country']?.toString() ?? '',
    stars:
        json['stars'] is int
            ? json['stars']
            : int.tryParse(json['stars']?.toString() ?? '') ?? 0,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    image: json['image']?.toString() ?? '',
    amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList(),
    type: json['type']?.toString() ?? 'Resort',
  );
}

class Car {
  final String id;
  final String brand;
  final String model;
  final String location;
  final double price; // Assuming price per day
  final String image;
  final String? provider;
  final String? type; // e.g. 'Sedan', 'SUV'
  final String fuelType; // e.g. 'Gasoline', 'Diesel', 'Electric'
  final int year; // Manufacturing year
  final String transmission; // e.g. 'Automatic', 'Manual'
  final List<String>? features; // e.g. ['GPS', 'Bluetooth', 'Sunroof']
  final int? seats; // Added
  final int? mileage; // Added (assuming km)
  final double? engineSize; // Added (assuming L)
  final String? color; // Added

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.location,
    required this.price,
    required this.image,
    this.provider,
    this.type,
    required this.fuelType,
    required this.year,
    required this.transmission,
    this.features,
    this.seats, // Added
    this.mileage, // Added
    this.engineSize, // Added
    this.color, // Added
  });

  factory Car.fromJson(Map<String, dynamic> json) => Car(
    id: json['id']?.toString() ?? '',
    brand: json['brand']?.toString() ?? '',
    model: json['model']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    image: json['image']?.toString() ?? '',
    provider: json['provider']?.toString(),
    type: json['type']?.toString(),
    fuelType: json['fuelType']?.toString() ?? 'Unknown',
    year:
        json['year'] is int
            ? json['year']
            : int.tryParse(json['year']?.toString() ?? '') ?? 0,
    transmission: json['transmission']?.toString() ?? 'Unknown',
    features: (json['features'] as List?)?.map((e) => e.toString()).toList(),
    seats:
        json['seats']
                is int // Added
            ? json['seats']
            : int.tryParse(json['seats']?.toString() ?? ''),
    mileage:
        json['mileage_km']
                is int // Added - matching 'mileage_km' from typical json
            ? json['mileage_km']
            : int.tryParse(json['mileage_km']?.toString() ?? ''),
    engineSize:
        (json['engine_l'] as num?)?.toDouble(), // Added - matching 'engine_l'
    color: json['color']?.toString(), // Added
  );
}

class Account {
  final String id; // Added unique ID
  final String email;
  final String phoneNumber;
  final String lastName;
  final String firstName;
  String
  password; // TODO: Implement secure password hashing in a real application
  String username;
  final Map<String, List<Map<String, dynamic>>> bookings;

  Account({
    required this.id, // Added
    required this.email,
    required this.phoneNumber,
    required this.lastName,
    required this.firstName,
    required this.password,
    required this.username,
    Map<String, List<Map<String, dynamic>>>? bookings,
  }) : bookings = bookings ?? {'flights': [], 'hotels': [], 'cars': []};

  // factory Account.fromJson(Map<String, dynamic> json) => Account(
  //       id: json['id'], // Added
  //       email: json['email'],
  //       phoneNumber: json['phoneNumber'],
  //       lastName: json['lastName'],
  //       firstName: json['firstName'],
  //       password: json['password'], // TODO: Handle hashed password retrieval
  //       username: json['username'],
  //       bookings: json['bookings'] != null
  //           ? (json['bookings'] as Map<String, dynamic>).map(
  //               (key, value) => MapEntry(
  //                 key,
  //                 (value as List<dynamic>)
  //                     .map((item) => item as Map<String, dynamic>)
  //                     .toList(),
  //               ),
  //             )
  //           : {'flights': [], 'hotels': [], 'cars': []},
  //     );

  // Map<String, dynamic> toJson() => {
  //       'id': id, // Added
  //       'email': email,
  //       'phoneNumber': phoneNumber,
  //       'lastName': lastName,
  //       'firstName': firstName,
  //       'password': password, // TODO: Store hashed password
  //       'username': username,
  //       'bookings': bookings,
  //     };
}
