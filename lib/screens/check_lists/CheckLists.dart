import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../Dashboard.dart';
import '../JobCards/Index.dart';
import '../Login.dart';
import '../Requsitions/Index.dart';
import '../UserProfile.dart';
import '../assiginments/Assignments.dart';
import '../assiginments/History.dart';
import '../device_returns/Index.dart';
import '../stocks/Allstocks.dart';

class CheckLists extends StatefulWidget {
  const CheckLists({super.key});

  @override
  _CheckListsState createState() => _CheckListsState();
}

class _CheckListsState extends State<CheckLists> with SingleTickerProviderStateMixin {
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _checkDateController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _checklists = [];
  bool _loading = false;
  bool isLoading = false;

  String? _customerId;
  String? _customerName;
  String? _vehicleId;
  String? _vehicleName;
  String? _rbtStatus = 'good'; // Default status
  String? _battStatus = 'good'; // Default status

  late TabController _tabController;

  final List<String> rbtOptions = ['good','not-good'];
  final List<String> battOptions = ['good', 'not-good'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _searchVehicle() async {
    final plateNumber = _plateNumberController.text.trim();
    if (plateNumber.isEmpty) {
      _showToast("Please enter a plate number");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        _showToast("User not authenticated");
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.100.105:8000/api/checklist/auto-fill'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'plate_number': plateNumber}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            _customerId = jsonResponse['customer_id'].toString();
            _customerName = jsonResponse['customername'];
            _vehicleId = jsonResponse['vehicle_id'].toString();
            _vehicleName = jsonResponse['vehicle_name'].toString();
          });
          _showToast("Vehicle searched currently present!!");
        } else {
          _showToast("Vehicle not found for the number");
        }
      } else {
        _handleError(response);
      }
    } catch (error) {
      _showToast("An error occurred: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  Future<void> _submitForm() async {
    if (_customerId == null || _vehicleId == null) {
      _showToast("Please search for a vehicle first.");
      return;
    }

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        _showToast("User not authenticated");
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.100.105:8000/api/checklist/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'vehicle_id': _vehicleId,
          'customer_id': _customerId,
          'plate_number': _plateNumberController.text,
          'rbt_status': _rbtStatus,
          'batt_status': _battStatus,
          'check_date': _checkDateController.text,
        }),
      );

      if (response.statusCode == 201) {
        _showToast("Checklist submitted successfully!");
      } else {
        _handleError(response);
      }
    } catch (error) {
      _showToast("An error occurred: $error");
    }
  }

  Future<void> _filterChecklists() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
      });

      final url = Uri.parse('http://192.168.100.105:8000/api/filter-by-date');

      try {
        final token = await storage.read(key: 'token');
        if (token == null) {
          _showToast("User not authenticated");
          return;
        }

        if (_startDateController.text.isEmpty || _endDateController.text.isEmpty) {
          _showToast("Please select both start and end dates.");
          return;
        }

        // Check if start date is before end date
        DateTime startDate = DateFormat('yyyy-MM-dd').parse(_startDateController.text);
        DateTime endDate = DateFormat('yyyy-MM-dd').parse(_endDateController.text);
        if (startDate.isAfter(endDate)) {
          _showToast("Start date must be before end date.");
          return;
        }

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'start_date': _startDateController.text,
            'end_date': _endDateController.text,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _checklists = data['data'] ?? [];
          });
          _showToast("Checklists retrieved successfully!");
        } else {
          _handleError(response);
        }
      } catch (error) {
        _showToast("An error occurred: $error");
      } finally {
        setState(() {
          _loading = false;
        });
      }
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
            builder: (context) => const AuthenticationPage(),
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
  void _handleError(http.Response response) {
    if (response.statusCode == 404) {
      _showToast("Vehicle or customer not found");
    } else if (response.statusCode == 422) {
      _showToast("Validation error");
    } else {
      _showToast("An error occurred. Please try again later.");
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('CheckLists', style: TextStyle(fontSize: 15.0)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.checklist), text: "CheckList"),
            Tab(icon: Icon(Icons.filter_alt), text: "Check a Car"),
          ],
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
                    builder: (context) => const UserProfile(),
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
                    builder: (context) => const Requisitions(),
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
                    builder: (context) => const Allstocks(),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // CheckList Tab
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _plateNumberController,
                      decoration: InputDecoration(
                        labelText: 'Plate Number',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchVehicle,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a plate number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25.0),
                    TextFormField(
                      controller: _checkDateController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Check Date',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, _checkDateController),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a check date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: _rbtStatus,
                      decoration: const InputDecoration(
                          labelText: 'RBT Status',
                        border: OutlineInputBorder(),
                      ),
                      items: rbtOptions.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _rbtStatus = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: _battStatus,
                      decoration: const InputDecoration(
                          labelText: 'Battery Status',
                        border: OutlineInputBorder(),
                      ),
                      items: battOptions.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _battStatus = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Filter by Date Tab
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _startDateController,
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, _startDateController),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a start date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _endDateController,
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, _endDateController),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an end date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _filterChecklists,
                      child: const Text('Submit CheckList'),
                    ),
                    const SizedBox(height: 16.0),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _checklists.length,
                      itemBuilder: (context, index) {
                        final checklist = _checklists[index];
                        return Card(
                          color: Colors.white,
                          elevation: 3.0,
                          child: ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PlateNumber: ${checklist['plate_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Vehicle: ${checklist['vehicle_name']}'),
                                Text('Client: ${checklist['customername']}'),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('RBT Status: ${checklist['rbt_status']}'),
                                Text('Battery Status: ${checklist['batt_status']}'),
                              ],
                            ),
                            trailing: Text('Check Date: ${checklist['check_date']}'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
