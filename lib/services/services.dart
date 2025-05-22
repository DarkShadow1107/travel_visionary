import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// Service classes for API calls, data fetching, and business logic will be added here.
// Example:
class FlightService {
  // Future<List<Flight>> searchFlights(...) async { ... }
}

// Add HotelService, CarService, BookingService, UserService similarly.

class DataService {
  Future<List<Flight>> loadFlights() async {
    final data = await rootBundle.loadString('assets/data/flights.json');
    final List<dynamic> jsonResult = json.decode(data);
    return jsonResult.map((e) => Flight.fromJson(e)).toList();
  }

  Future<List<Hotel>> loadHotels() async {
    final data = await rootBundle.loadString('assets/data/hotels.json');
    final List<dynamic> jsonResult = json.decode(data);
    return jsonResult.map((e) => Hotel.fromJson(e)).toList();
  }

  Future<List<Car>> loadCars() async {
    final data = await rootBundle.loadString('assets/data/cars.json');
    final List<dynamic> jsonResult = json.decode(data);
    return jsonResult.map((e) => Car.fromJson(e)).toList();
  }
}

class BookingService {
  static const String _key = 'bookings';

  Future<List<Map<String, dynamic>>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }

  Future<void> addBooking(Map<String, dynamic> booking) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    data.add(json.encode(booking));
    await prefs.setStringList(_key, data);
  }

  Future<void> bookCar(
    Car car,
    DateTime pickupDate,
    DateTime dropoffDate,
  ) async {
    final bookingDetails = {
      'type': 'car',
      'carId': car.id,
      'brand': car.brand,
      'model': car.model,
      'pickupDate': pickupDate.toIso8601String(),
      'dropoffDate': dropoffDate.toIso8601String(),
      'totalPrice':
          car.price * (dropoffDate.difference(pickupDate).inDays.abs() + 1),
      'bookedAt': DateTime.now().toIso8601String(),
    };
    await addBooking(bookingDetails);
    // You might want to add more sophisticated logic here,
    // like checking availability or interacting with a backend.
    print('Car booked: ${car.brand} ${car.model}');
  }

  Future<void> clearBookings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
