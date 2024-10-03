import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Dashboard.dart';
import '../JobCards/Index.dart';
import '../Login.dart';
import '../Requsitions/Index.dart';
import '../UserProfile.dart';
import '../assiginments/Assignments.dart';
import '../assiginments/History.dart';
import '../check_lists/CheckLists.dart';
import '../stocks/Allstocks.dart';

class DeviceReturns extends StatefulWidget {
  const DeviceReturns({super.key});

  @override
  _DeviceReturnsState createState() => _DeviceReturnsState();
}

class _DeviceReturnsState extends State<DeviceReturns> {
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  bool isLoading = false;
  bool isFetchingReturns = false;

  String? _plateNumber;
  String? _customerId;
  String? _customerName;
  String? _imeiNumber;


  List<dynamic> _returns = []; // To hold the device return records

  // Method to search for vehicle and auto-fill details
  Future<void> _searchVehicle() async {
    final plateNumber = _plateNumberController.text.trim();
    if (plateNumber.isEmpty) {
      _showToast("Please enter a plate number");
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      final token = await storage.read(key: 'token'); // Read the token from storage
      if (token == null) {
        _showToast("User not authenticated");
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.100.105:8000/api/device-return/filter'),
        headers: {
          'Authorization': 'Bearer $token', // Authenticated request
          'Content-Type': 'application/json',
        },
        body: json.encode({'plate_number': plateNumber}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            _plateNumber = jsonResponse['plate_number'] as String?;
            _customerId = jsonResponse['customer_id'].toString(); // Keep as string
            _customerName = jsonResponse['customername'] as String?;
            _imeiNumber = jsonResponse['imei_number'] != null
                ? jsonResponse['imei_number'].toString() // Convert IMEI to string if needed
                : null; // Handle null case
          });
          _showToast("Vehicle details fetched successfully");
        } else {
          _showToast(jsonResponse['message'] ?? "Vehicle not found for the number");
        }
      } else {
        _handleError(response);
      }
    } catch (error) {
      _showToast("An error occurred: $error");
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  // Method to submit the return device information
  Future<void> _submitReturn() async {
    if (_reasonController.text.isEmpty) {
      _showToast("Please enter a reason for returning the device");
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      final token = await storage.read(key: 'token'); // Read the token from storage
      if (token == null) {
        _showToast("User not authenticated");
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.100.105:8000/api/device-return/store'),
        headers: {
          'Authorization': 'Bearer $token', // Authenticated request
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'plate_number': _plateNumber,
          'customer_id': _customerId,
          'imei_number': _imeiNumber,
          'reason': _reasonController.text,
        }),
      );

      if (response.statusCode == 201) {
        _showToast("Return device submitted successfully");
        // Clear fields if needed
        _plateNumberController.clear();
        _reasonController.clear();
        setState(() {
          _plateNumber = null;
          _customerId = null;
          _customerName = null;
          _imeiNumber = null;
        });
      } else {
        _handleError(response);
      }
    } catch (error) {
      _showToast("An error occurred: $error");
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
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

  // Method to fetch all device return records
  Future<void> _fetchReturns() async {
    setState(() {
      isFetchingReturns = true; // Show loading indicator for fetch
    });

    try {
      final token = await storage.read(key: 'token'); // Read the token from storage
      if (token == null) {
        _showToast("User not authenticated");
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.100.105:8000/api/device-return/all'),
        headers: {
          'Authorization': 'Bearer $token', // Authenticated request
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            _returns = jsonResponse['data'] as List<dynamic>; // Store the fetched records
          });
        } else {
          _showToast(jsonResponse['message'] ?? "Failed to fetch device return records");
        }
      } else {
        _handleError(response);
      }
    } catch (error) {
      _showToast("An error occurred: $error");
    } finally {
      setState(() {
        isFetchingReturns = false; // Hide loading indicator
      });
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleError(http.Response response) {
    String message = 'Error: ${response.statusCode}';
    if (response.body.isNotEmpty) {
      final jsonResponse = json.decode(response.body);
      message = jsonResponse['message'] ?? message;
    }
    _showToast(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return device',style: TextStyle(
          fontSize: 15.0,
        ),),
        backgroundColor: Colors.blue, // Set the background color of the AppBar
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
                    builder: (context) => Dashboard(),
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
                    builder: (context) => Assignments(),
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
                    builder: (context) => Jobcards(),
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
                    builder: (context) => CheckLists(),
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
                    builder: (context) => DeviceReturns(),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _plateNumberController,
              decoration: const InputDecoration(
                labelText: 'Enter Plate Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: isLoading ? null : _searchVehicle,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Search',style: TextStyle(
                color: Colors.blue,
              ),),
            ),
            const SizedBox(height: 20.0),
            if (_plateNumber != null) ...[
              Text('Plate Number: $_plateNumber'),
              Text('Customer ID: $_customerId'),
              Text('Customer Name: $_customerName'),
              Text('Device Number: $_imeiNumber'),
              const SizedBox(height: 20.0),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Return',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: isLoading ? null : _submitReturn,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Return',style: TextStyle(
                  color: Colors.blue,
                ),),
              ),
            ],
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: isFetchingReturns ? null : _fetchReturns,
              child: isFetchingReturns
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Fetch Returns',style: TextStyle(
                color: Colors.blue,
              ),),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: _returns.isNotEmpty
                  ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Show 2 cards horizontally
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _returns.length,
                itemBuilder: (context, index) {
                  final returnRecord = _returns[index];
                  return Card(
                    elevation: 3,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PlateNumber: ${returnRecord['plate_number']}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Client: ${returnRecord['customername']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'DeviceNumber: ${returnRecord['imei_number']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${returnRecord['status'] ?? 'pending'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reason: ${returnRecord['reason']}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                },
              )
                  : const Center(child: Text('No returns found.')),
            ),
          ],
        ),
      ),
    );
  }
}
