import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added for state management
import '../models/models.dart';
import '../services/services.dart';
// Import BookingHistoryScreen

// Enum to manage the state of the profile screen (logged out, logged in, creating account, editing account)
enum ProfileState { loggedOut, loggedIn, creatingAccount, editingAccount }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileState _currentProfileState = ProfileState.loggedOut;
  Account? _currentAccount;

  // Controllers for forms
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();

  // Controllers for editing
  final _editUsernameController = TextEditingController();
  final _editPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status when the screen initializes
  }

  void _checkLoginStatus() async {
    final accountService = Provider.of<AccountService>(context, listen: false);
    final account = await accountService.getCurrentAccount();
    if (account != null) {
      setState(() {
        _currentAccount = account;
        _currentProfileState = ProfileState.loggedIn;
        _editUsernameController.text = account.username;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _editUsernameController.dispose();
    _editPasswordController.dispose();
    super.dispose();
  }

  void _login() async {
    final accountService = Provider.of<AccountService>(context, listen: false);
    // Use emailOrUsername for login
    final account = await accountService.login(
      _emailController.text,
      _passwordController.text,
    );
    if (account != null) {
      setState(() {
        _currentAccount = account;
        _currentProfileState = ProfileState.loggedIn;
        // Populate edit fields when logged in
        _editUsernameController.text = account.username;
      });
      _passwordController.clear(); // Clear password field after login attempt
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials or account not found.'),
        ),
      );
      _passwordController.clear();
    }
  }

  void _createAccount() async {
    final accountService = Provider.of<AccountService>(context, listen: false);
    // Use the new createAccount method from AccountService
    final errorMessage = await accountService.createAccount(
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      lastName: _lastNameController.text,
      firstName: _firstNameController.text,
      password: _passwordController.text,
      username: _usernameController.text,
    );

    if (errorMessage == null) {
      // null means success
      // Retrieve the newly created and logged-in account
      final newLoggedInAccount = await accountService.getCurrentAccount();
      setState(() {
        _currentAccount = newLoggedInAccount;
        _currentProfileState = ProfileState.loggedIn;
        if (newLoggedInAccount != null) {
          _editUsernameController.text = newLoggedInAccount.username;
        }
      });
      _emailController.clear();
      _passwordController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      _usernameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! You are now logged in.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create account: $errorMessage')),
      );
    }
  }

  void _updateAccount() async {
    if (_currentAccount == null) return;
    final accountService = Provider.of<AccountService>(context, listen: false);

    String? newUsername =
        _editUsernameController.text.isNotEmpty &&
                _editUsernameController.text != _currentAccount!.username
            ? _editUsernameController.text
            : null;
    String? newPassword =
        _editPasswordController.text.isNotEmpty
            ? _editPasswordController.text
            : null;
    // Add phone number editing capability if desired, for now it's not included in this edit form

    if (newUsername == null && newPassword == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to update.')));
      setState(() {
        _currentProfileState = ProfileState.loggedIn; // Go back to profile view
      });
      return;
    }

    final success = await accountService.updateAccount(
      _currentAccount!.email,
      newUsername: newUsername,
      newPassword: newPassword,
      // newPhoneNumber: newPhoneNumber, // Add if phone editing is implemented
    );

    if (success) {
      // Refresh account details
      final updatedAccount = await accountService.getAccount(
        _currentAccount!.email,
      );
      setState(() {
        _currentAccount = updatedAccount;
        _currentProfileState = ProfileState.loggedIn;
        if (updatedAccount != null) {
          _editUsernameController.text = updatedAccount.username;
        }
        _editPasswordController.clear(); // Clear password field
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update account. Username might be taken.'),
        ),
      );
    }
  }

  void _logout() async {
    // Make it async
    final accountService = Provider.of<AccountService>(context, listen: false);
    await accountService.logout(); // Call logout from service
    setState(() {
      _currentAccount = null;
      _currentProfileState = ProfileState.loggedOut;
      _emailController.clear();
      _passwordController.clear();
      _editUsernameController.clear();
      _editPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow main gradient to show
      appBar: AppBar(
        title: Text(
          _currentProfileState == ProfileState.loggedIn &&
                  _currentAccount != null
              ? 'Welcome, ${_currentAccount!.firstName}'
              : 'Profile / Account',
        ),
        actions: [
          if (_currentProfileState == ProfileState.loggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            // Added to prevent overflow on smaller screens
            child: _buildProfileContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    switch (_currentProfileState) {
      case ProfileState.loggedOut:
        return _buildLoginForm();
      case ProfileState.creatingAccount:
        return _buildCreateAccountForm();
      case ProfileState.loggedIn:
        return _buildLoggedInView();
      case ProfileState.editingAccount:
        return _buildEditAccountForm();
    }
  }

  Widget _buildLoginForm() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1B1A55), // Form background color
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Reduced padding
        child: ConstrainedBox(
          // Added to constrain width
          constraints: const BoxConstraints(
            maxWidth: 400,
          ), // Max width for the form
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Login',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFE3FEF7),
                ), // Brighter text
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(
                  color: Color(0xFFE3FEF7),
                ), // Brighter input text
                decoration: InputDecoration(
                  labelText: 'Email or Username',
                  labelStyle: const TextStyle(
                    color: Color(0xFF77B0AA),
                  ), // Brighter label
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded borders
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(
                  color: Color(0xFFE3FEF7),
                ), // Brighter input text
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(
                    color: Color(0xFF77B0AA),
                  ), // Brighter label
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF77B0AA), // Button color
                  foregroundColor: const Color(0xFF070F2B), // Button text color
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    () => setState(
                      () => _currentProfileState = ProfileState.creatingAccount,
                    ),
                child: const Text(
                  'Create New Account',
                  style: TextStyle(color: Color(0xFF77B0AA)), // Brighter text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountForm() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1B1A55), // Form background color
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Reduced padding
        child: ConstrainedBox(
          // Added to constrain width
          constraints: const BoxConstraints(
            maxWidth: 400,
          ), // Max width for the form
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFE3FEF7),
                ), // Brighter text
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstNameController,
                style: const TextStyle(color: Color(0xFFE3FEF7)),
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: const TextStyle(color: Color(0xFF77B0AA)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                style: const TextStyle(color: Color(0xFFE3FEF7)),
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: const TextStyle(color: Color(0xFF77B0AA)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Color(0xFFE3FEF7)),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Color(0xFF77B0AA)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Color(0xFFE3FEF7)),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Color(0xFF77B0AA)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Color(0xFFE3FEF7)),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: Color(0xFF77B0AA)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Color(0xFFE3FEF7)),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Color(0xFF77B0AA)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF77B0AA), // Button color
                  foregroundColor: const Color(0xFF070F2B), // Button text color
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Clear fields when switching back to login
                  _firstNameController.clear();
                  _lastNameController.clear();
                  // _emailController.clear(); // Keep email if user was trying to log in
                  _usernameController.clear();
                  _phoneController.clear();
                  // _passwordController.clear(); // Keep password if user was trying to log in
                  setState(() => _currentProfileState = ProfileState.loggedOut);
                },
                child: const Text(
                  'Back to Login',
                  style: TextStyle(color: Color(0xFF77B0AA)), // Brighter text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInView() {
    if (_currentAccount == null) {
      return const Text('Error: No account details found.');
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Account Details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFFE3FEF7), // Brighter text for visibility
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          // Added to make the card shorter in width
          constraints: const BoxConstraints(
            maxWidth: 350,
          ), // Limits the width of the card
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: const Color(
              0xFF070F2B,
            ).withOpacity(0.8), // Slightly transparent dark card
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ), // Reduced vertical padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Name:',
                    '${_currentAccount!.firstName} ${_currentAccount!.lastName}',
                  ),
                  _buildDetailRow('Username:', _currentAccount!.username),
                  _buildDetailRow('Email:', _currentAccount!.email),
                  _buildDetailRow('Phone:', _currentAccount!.phoneNumber),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed:
              () => setState(
                () => _currentProfileState = ProfileState.editingAccount,
              ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF77B0AA), // Button color from login
            foregroundColor: const Color(
              0xFF070F2B,
            ), // Button text color from login
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Account Settings'),
        ),
        // Removed View Booking History Button
        // const SizedBox(height: 12),
        // ElevatedButton(
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => BookingHistoryScreen(account: _currentAccount!),
        //       ),
        //     );
        //   },
        //   child: const Text('View Booking History'),
        // ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // Slightly increased vertical padding for rows
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF77B0AA),
              fontWeight: FontWeight.bold,
              fontSize: 15, // Increased font size
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFFE3FEF7),
                fontSize: 15, // Increased font size
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditAccountForm() {
    return Card(
      // Added Card similar to login form
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1B1A55), // Form background color from login
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
          ), // Max width for the form
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFE3FEF7), // Brighter text from login
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _editUsernameController,
                style: const TextStyle(
                  color: Color(0xFFE3FEF7),
                ), // Brighter input text from login
                decoration: InputDecoration(
                  labelText: 'New Username (optional)',
                  labelStyle: const TextStyle(
                    color: Color(0xFF77B0AA),
                  ), // Brighter label from login
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _editPasswordController,
                obscureText: true,
                style: const TextStyle(
                  color: Color(0xFFE3FEF7),
                ), // Brighter input text from login
                decoration: InputDecoration(
                  labelText: 'New Password (optional)',
                  labelStyle: const TextStyle(
                    color: Color(0xFF77B0AA),
                  ), // Brighter label from login
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF77B0AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3FEF7)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateAccount,
                style: ElevatedButton.styleFrom(
                  // Style from login button
                  backgroundColor: const Color(0xFF77B0AA),
                  foregroundColor: const Color(0xFF070F2B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Update Account'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    () => setState(
                      () => _currentProfileState = ProfileState.loggedIn,
                    ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF77B0AA),
                  ), // Style from login form's TextButton
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Make sure to provide AccountService in your main.dart or a relevant ancestor widget:
// runApp(
//   MultiProvider(
//     providers: [
//       Provider<AccountService>(create: (_) => AccountService()),
//       // ... other providers
//     ],
//     child: MyApp(),
//   ),
// );
