import 'dart:convert';
// import 'dart:io'; // Import for File operations - Removed
import 'package:flutter/services.dart' show rootBundle;
// import 'package:path_provider/path_provider.dart'; // Import for getting documents directory - Removed
import 'package:crypto/crypto.dart'; // For password hashing
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class AccountService {
  Account? _currentAccount; // To store the currently logged-in user
  List<Account> _accounts = []; // In-memory list of accounts

  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // data being hashed
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<List<Account>> _loadAccounts() async {
    // Return the in-memory list.
    // Initial data loading from assets/data/accounts.json has been removed
    // as Account.fromJson is no longer available.
    if (_accounts.isEmpty) {
      // You could potentially add some default/test accounts programmatically here if needed
      print('Account list is empty. Accounts will be created in memory only.');
    }
    return _accounts;
  }

  Future<void> _saveAccounts(List<Account> accounts) async {
    _accounts = accounts;
    // No file saving needed as per requirement
  }

  Future<Account?> getAccount(String email) async {
    final accounts =
        await _loadAccounts(); // This now gets from in-memory _accounts
    try {
      return accounts.firstWhere((account) => account.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<Account?> login(String emailOrUsername, String password) async {
    final accounts = await _loadAccounts(); // Gets from in-memory
    final hashedPassword = _hashPassword(password);
    try {
      final account = accounts.firstWhere(
        (account) =>
            (account.email == emailOrUsername ||
                account.username == emailOrUsername) &&
            account.password == hashedPassword,
      );
      _currentAccount = account; // Set current user on successful login
      await _saveCurrentAccountEmail(account.email); // Persist current user
      return account;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    _currentAccount = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserEmail');
  }

  Future<void> _saveCurrentAccountEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserEmail', email);
  }

  Future<Account?> getCurrentAccount() async {
    if (_currentAccount != null) return _currentAccount;
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('currentUserEmail');
    if (email != null) {
      _currentAccount = await getAccount(email);
      return _currentAccount;
    }
    return null;
  }

  Future<String?> createAccount({
    required String email,
    required String phoneNumber,
    required String lastName,
    required String firstName,
    required String password,
    required String username,
  }) async {
    List<Account> accounts = await _loadAccounts(); // Gets from in-memory
    if (accounts.any((acc) => acc.email == email)) {
      return "Email already exists.";
    }
    if (accounts.any((acc) => acc.username == username)) {
      return "Username already exists.";
    }
    // Consider if phone number should be unique, currently it is.
    if (accounts.any((acc) => acc.phoneNumber == phoneNumber)) {
      return "Phone number already exists.";
    }

    final hashedPassword = _hashPassword(password);
    // Generate a unique ID for the new account
    final String newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newAccount = Account(
      id: newId, // Add the generated ID
      email: email,
      phoneNumber: phoneNumber,
      lastName: lastName,
      firstName: firstName, // Corrected: Use the parameter firstName
      password: hashedPassword,
      username: username,
      bookings: {}, // Initialize with empty bookings
    );
    accounts.add(newAccount);
    await _saveAccounts(accounts); // Saves to in-memory list
    // Automatically log in the user after account creation
    _currentAccount = newAccount;
    await _saveCurrentAccountEmail(newAccount.email);
    return null; // Indicates success
  }

  Future<bool> updateAccount(
    String email, {
    String? newUsername,
    String? newPassword,
    String? newPhoneNumber,
  }) async {
    List<Account> accounts = await _loadAccounts(); // Gets from in-memory
    int accountIndex = accounts.indexWhere((acc) => acc.email == email);

    if (accountIndex == -1) {
      return false; // Account not found
    }

    Account currentAccountData = accounts[accountIndex];
    String updatedPassword = currentAccountData.password;
    String updatedUsername = currentAccountData.username;
    String updatedPhoneNumber = currentAccountData.phoneNumber;

    if (newUsername != null) {
      if (accounts.any(
        (acc) => acc.username == newUsername && acc.email != email,
      )) {
        return false; // Username already taken
      }
      updatedUsername = newUsername;
    }

    if (newPhoneNumber != null) {
      if (accounts.any(
        (acc) => acc.phoneNumber == newPhoneNumber && acc.email != email,
      )) {
        return false; // Phone number already taken
      }
      updatedPhoneNumber = newPhoneNumber;
    }

    if (newPassword != null) {
      updatedPassword = _hashPassword(newPassword);
    }

    // Create a new Account object with updated details
    Account updatedAccount = Account(
      id: currentAccountData.id, // Preserve existing ID
      email: currentAccountData.email,
      phoneNumber: updatedPhoneNumber,
      lastName: currentAccountData.lastName,
      firstName: currentAccountData.firstName,
      password: updatedPassword,
      username: updatedUsername,
      bookings: currentAccountData.bookings,
    );

    accounts[accountIndex] = updatedAccount;
    await _saveAccounts(accounts); // Saves to in-memory list
    if (_currentAccount?.email == email) {
      // Update current account if it's the one being edited
      _currentAccount = updatedAccount;
    }
    return true;
  }

  // Add this method for development/testing if needed to get all accounts
  Future<List<Account>> DEV_ONLY_getAllAccounts() async {
    return await _loadAccounts(); // Gets from in-memory
  }

  // Add this method to update bookings for an account
  Future<void> updateAccountBookings(Account updatedAccount) async {
    List<Account> accounts = await _loadAccounts(); // Gets from in-memory
    int accountIndex = accounts.indexWhere(
      (acc) => acc.email == updatedAccount.email,
    );
    if (accountIndex != -1) {
      accounts[accountIndex] = updatedAccount;
      await _saveAccounts(accounts);
      if (_currentAccount?.email == updatedAccount.email) {
        _currentAccount = updatedAccount; // Update current user if it matches
      }
    }
  }

  Future<void> clearUserBookings(String email) async {
    List<Account> accounts = await _loadAccounts(); // Gets from in-memory
    int accountIndex = accounts.indexWhere((acc) => acc.email == email);
    if (accountIndex != -1) {
      Account account = accounts[accountIndex];
      account.bookings.clear(); // Clear all bookings for the user
      account.bookings['flights'] = []; // Ensure keys exist with empty lists
      account.bookings['hotels'] = [];
      account.bookings['cars'] = [];
      accounts[accountIndex] = account;
      await _saveAccounts(accounts);
      if (_currentAccount?.email == email) {
        _currentAccount = account; // Update current user if it matches
      }
    }
  }

  Future<void> addBookedItem(
    String itemType,
    Map<String, dynamic> itemJson,
  ) async {
    final currentUser = await getCurrentAccount();
    if (currentUser == null) {
      print("No user logged in to add booking.");
      return; // Or throw an error
    }

    List<Account> accounts = await _loadAccounts(); // Gets from in-memory
    int accountIndex = accounts.indexWhere(
      (acc) => acc.email == currentUser.email,
    );

    if (accountIndex != -1) {
      Account account = accounts[accountIndex];
      // Ensure the list for the itemType exists
      if (!account.bookings.containsKey(itemType) ||
          account.bookings[itemType] == null) {
        account.bookings[itemType] = [];
      }
      account.bookings[itemType]!.add(itemJson);

      accounts[accountIndex] = account;
      await _saveAccounts(accounts);
      _currentAccount = account; // Update the in-memory current account
      print("$itemType booking added for ${currentUser.email}");
    } else {
      print("Could not find account for ${currentUser.email} to add booking.");
    }
  }

  Future<void> addFlightBooking(
    Flight flight,
    String selectedClass,
    int numTickets,
  ) async {
    final bookingDetails = {
      'type': 'flight',
      'flightId': flight.id,
      'origin': flight.origin,
      'destination': flight.destination,
      'carrier': flight.carrier,
      'departureTime': flight.departureTime,
      'arrivalTime': flight.arrivalTime,
      'selectedClass': selectedClass,
      'numTickets': numTickets,
      'totalPrice': (flight.classPrices[selectedClass] ?? 0.0) * numTickets,
      'bookedAt': DateTime.now().toIso8601String(),
    };
    await addBookedItem('flights', bookingDetails);
  }

  Future<void> addHotelBooking(
    Hotel hotel,
    DateTime checkInDate,
    DateTime checkOutDate,
    int numGuests,
    int numRooms,
  ) async {
    final bookingDetails = {
      'type': 'hotel',
      'hotelId': hotel.id,
      'name': hotel.name,
      'city': hotel.city,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'numGuests': numGuests,
      'numRooms': numRooms,
      'totalPrice':
          hotel.price *
          numRooms *
          (checkOutDate.difference(checkInDate).inDays.abs() + 1),
      'bookedAt': DateTime.now().toIso8601String(),
    };
    await addBookedItem('hotels', bookingDetails);
  }

  Future<void> addCarBooking(
    Car car,
    DateTime pickupDate,
    DateTime dropoffDate,
  ) async {
    final bookingDetails = {
      'type': 'car',
      'carId': car.id,
      'brand': car.brand,
      'model': car.model,
      'location': car.location,
      'pickupDate': pickupDate.toIso8601String(),
      'dropoffDate': dropoffDate.toIso8601String(),
      'totalPrice':
          car.price * (dropoffDate.difference(pickupDate).inDays.abs() + 1),
      'bookedAt': DateTime.now().toIso8601String(),
    };
    await addBookedItem('cars', bookingDetails);
  }

  // Method to get bookings for the current user
  Future<Map<String, List<Map<String, dynamic>>>>
  getCurrentUserBookings() async {
    final currentUser = await getCurrentAccount();
    if (currentUser != null) {
      // Refresh the account data to get the latest bookings
      final refreshedAccount = await getAccount(currentUser.email);
      return refreshedAccount?.bookings ??
          {'flights': [], 'hotels': [], 'cars': []};
    }
    return {'flights': [], 'hotels': [], 'cars': []};
  }
}

// Remove or comment out the old BookingService if it's fully replaced
/*
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
    print('Car booked: ${car.brand} ${car.model}');
  }

  Future<void> clearBookings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
*/
