import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Dashboard.dart';
import '../JobCards/Index.dart';
import '../Login.dart';
import '../UserProfile.dart';
import '../assiginments/Assignments.dart';
import '../assiginments/History.dart';
import '../check_lists/CheckLists.dart';
import '../device_returns/Index.dart';
import '../stocks/Allstocks.dart';
import 'Index.dart';

class AddRequisition extends StatefulWidget {
  const AddRequisition({super.key});

  @override
  _AddRequisitionState createState() => _AddRequisitionState();
}

class _AddRequisitionState extends State<AddRequisition> {
  final _quantityController = TextEditingController();
  final _descriptionsController = TextEditingController();
  final _masterController = TextEditingController();
  final _IButtonController = TextEditingController();
  final _buzzerController = TextEditingController();
  final _panickButtonController = TextEditingController();
  String? _userId;
  final storage = FlutterSecureStorage();
  bool _isSubmitting = false;

  // Variables for validation error messages
  String? _masterError;
  String? _IButtonError;
  String? _buzzerError;
  String? _panickButtonError;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.100.105:8000/api/user_logged_user_id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _userId = jsonResponse['user_id'].toString(); // Ensure user_id is a string
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch user ID')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching user ID')),
      );
    }
  }

  // Method to validate the input
  bool _validateInputs() {
    setState(() {
      // Reset error messages
      _masterError = null;
      _IButtonError = null;
      _buzzerError = null;
      _panickButtonError = null;
    });

    bool isValid = true;

    // Validate master input
    if (_masterController.text.isEmpty || int.tryParse(_masterController.text) == null) {
      _masterError = 'Master must be a valid integer';
      isValid = false;
    }

    // Validate I Button input
    if (_IButtonController.text.isEmpty || int.tryParse(_IButtonController.text) == null) {
      _IButtonError = 'I Button must be a valid integer';
      isValid = false;
    }

    // Validate Buzzer input
    if (_buzzerController.text.isEmpty || int.tryParse(_buzzerController.text) == null) {
      _buzzerError = 'Buzzer must be a valid integer';
      isValid = false;
    }

    // Validate panick_button input
    if (_panickButtonController.text.isEmpty || int.tryParse(_panickButtonController.text) == null) {
      _panickButtonError = 'Panick Button must be a valid integer';
      isValid = false;
    }

    return isValid; // Return true if all validations passed
  }

  Future<void> _logout() async {
    try {
      final token = await storage.read(key: 'token'); // Read token from FlutterSecureStorage

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.100.105:8000/api/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Clear the token
        await storage.delete(key: 'token');

        // Navigate to the login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AuthenticationPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log out')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during logout')),
      );
    }
  }

  Future<void> _submitRequisition() async {
    setState(() {
      _isSubmitting = true;
    });

    if (!_validateInputs()) {
      // If validation fails, stop submission
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No token found')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.100.105:8000/api/device-requisitions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'descriptions': _descriptionsController.text,
          'user_id': _userId,
          'master': int.tryParse(_masterController.text) ?? 0,
          'I_button': int.tryParse(_IButtonController.text) ?? 0,
          'buzzer': int.tryParse(_buzzerController.text) ?? 0,
          'panick_button': int.tryParse(_panickButtonController.text) ?? 0,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context); // Go back to the previous screen
      } else {
        final jsonResponse = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add requisition: ${jsonResponse['message']}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Requisition', style: TextStyle(
          fontSize: 15.0, fontFamily: 'EuclidCircularA',
        )),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _masterController,
                decoration: InputDecoration(
                  labelText: 'Master',
                  border: const OutlineInputBorder(),
                  errorText: _masterError, // Show error message
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _IButtonController,
                decoration: InputDecoration(
                  labelText: 'I Button',
                  border: const OutlineInputBorder(),
                  errorText: _IButtonError, // Show error message
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _buzzerController,
                decoration: InputDecoration(
                  labelText: 'Buzzer',
                  border: const OutlineInputBorder(),
                  errorText: _buzzerError, // Show error message
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _panickButtonController,
                decoration: InputDecoration(
                  labelText: 'Panick Button',
                  border: const OutlineInputBorder(),
                  errorText: _panickButtonError, // Show error message
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionsController,
                decoration: const InputDecoration(
                  labelText: 'Descriptions',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitRequisition,
                child: Text('Submit', style: TextStyle(
                  fontSize: 12.0, fontFamily: 'EuclidCircularA',
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Dashboard(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfile(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('New Assignment',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Assignments(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Assignments History',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssignmentsHistory(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.reorder),
              title: const Text('Requisitions',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Requisitions(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Stock',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Allstocks(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('JobCards',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Jobcards(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('Check Lists',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckLists(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('Returns',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceReturns(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout',style:
              TextStyle(
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
              ),),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
