import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../Dashboard.dart';
import '../Login.dart';
import '../Requsitions/Index.dart';
import '../UserProfile.dart';
import '../assiginments/Assignments.dart';
import '../assiginments/History.dart';
import '../check_lists/CheckLists.dart';
import '../device_returns/Index.dart';
import '../stocks/Allstocks.dart';
import 'Index.dart';

class AddJobCard extends StatefulWidget {
  const AddJobCard({super.key});

  @override
  _AddJobCardState createState() => _AddJobCardState();
}

class _AddJobCardState extends State<AddJobCard> {
  // Controllers for form fields
  final _contactPersonController = TextEditingController();
  final _carPlateNumberController = TextEditingController();
  final _imeiNumberController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _physicalLocationController = TextEditingController();
  final _problemReportedController = TextEditingController();
  final _workDoneController = TextEditingController();
  final _clientCommentController = TextEditingController();
  final _dateAttendedController = TextEditingController();

  String? _selectedNatureOfProblem;
  String? _selectedServiceType;
  DateTime? _selectedDate;
  String? _selectedCustomerId;
  bool _isSubmitting = false;
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  List<dynamic> _customers = [];

  // Image file paths
  File? _preWorkDoneImage;
  File? _postWorkDoneImage;
  File? _carPlateNumberImage;
  File? _tamperingEvidenceImage;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Lists for dropdown options
  final List<String> _natureOfProblems = [
    'sim card problem',
    'wiring problem',
    'loose connection',
    'tampering by using ignition system',
    'tampering by using switch',
    'tampering by using ground',
    'tampering by using earth wire',
    'device location',
    'device is worn out',
    'Car electrical system',
    'Swollen Battery',
    'Eaten wires',
    'others',
  ];

  final List<String> _serviceTypes = [
    'new installation',
    'skipping',
    'noTransmission',
    'others',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    // Dispose of controllers
    _contactPersonController.dispose();
    _carPlateNumberController.dispose();
    _imeiNumberController.dispose();
    _mobileNumberController.dispose();
    _physicalLocationController.dispose();
    _problemReportedController.dispose();
    _workDoneController.dispose();
    _clientCommentController.dispose();
    _dateAttendedController.dispose();
    super.dispose();
  }

  // Fetch Customers Logic
  Future<void> _fetchCustomers() async {
    try {
      final token = await storage.read(key: 'token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token not found')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.100.105:8000/api/fetchcustomer'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (mounted) {
          setState(() {
            _customers = jsonResponse['assignments']?.map((customer) {
              return {
                'customer_id': customer['customer_id'],
                'customername': customer['customername'],
              };
            }).toList() ?? [];
            isLoading = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching customers')),
        );
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Function to pick images
  Future<void> _pickImage(String type) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case 'pre_workdone_picture':
            _preWorkDoneImage = File(pickedFile.path);
            break;
          case 'post_workdone_picture':
            _postWorkDoneImage = File(pickedFile.path);
            break;
          case 'carPlateNumber_picture':
            _carPlateNumberImage = File(pickedFile.path);
            break;
          case 'tampering_evidence_picture':
            _tamperingEvidenceImage = File(pickedFile.path);
            break;
        }
      });
    }
  }

  // Submit job card to the API
  Future<void> _submitJobCard() async {
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to create a job card.')),
        );
        return; // User is not authenticated
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.100.105:8000/api/jobcards'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Adding fields to the request
      request.fields['customer_id'] = _selectedCustomerId ?? '';
      request.fields['imei_number'] = _imeiNumberController.text;
      request.fields['plate_number'] = _carPlateNumberController.text;
      request.fields['contact_person'] = _contactPersonController.text;
      request.fields['mobile_number'] = _mobileNumberController.text;
      request.fields['physical_location'] = _physicalLocationController.text;
      request.fields['problem_reported'] = _problemReportedController.text;
      request.fields['natureOf_ProblemAt_site'] = _selectedNatureOfProblem ?? '';
      request.fields['service_type'] = _selectedServiceType ?? '';
      request.fields['date_attended'] = _dateAttendedController.text.isNotEmpty ? _dateAttendedController.text : '';
      request.fields['work_done'] = _workDoneController.text;
      request.fields['client_comment'] = _clientCommentController.text;

      // Adding images if available
      if (_preWorkDoneImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'pre_workdone_picture',
          _preWorkDoneImage!.path,
        ));
      }
      if (_postWorkDoneImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'post_workdone_picture',
          _postWorkDoneImage!.path,
        ));
      }
      if (_carPlateNumberImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'carPlateNumber_picture',
          _carPlateNumberImage!.path,
        ));
      }
      if (_tamperingEvidenceImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'tampering_evidence_picture',
          _tamperingEvidenceImage!.path,
        ));
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        final responseData = await http.Response.fromStream(response);
        final jsonResponse = json.decode(responseData.body);
        if (jsonResponse['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job Card added successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Jobcards(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['message'] ?? 'Error adding job card')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add job card')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create JobCard', style: TextStyle(
          fontSize: 15.0, fontFamily: 'EuclidCircularA',
        )),
        backgroundColor: Colors.blue,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Customer',border: OutlineInputBorder(),),
                value: _selectedCustomerId,
                onChanged: (value) {
                  setState(() {
                    _selectedCustomerId = value;
                  });
                },
                items: _customers.map((customer) {
                  return DropdownMenuItem<String>(
                    value: customer['customer_id'].toString(),
                    child: Text(customer['customername']),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _imeiNumberController,
                decoration: const InputDecoration(
                    labelText: 'Device Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _carPlateNumberController,
                decoration: const InputDecoration(
                    labelText: 'Car Plate Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mobileNumberController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _physicalLocationController,
                decoration: const InputDecoration(
                  labelText: 'Physical Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _problemReportedController,
                decoration: const InputDecoration(
                  labelText: 'Problem Reported',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Nature of Problem',
                  border: OutlineInputBorder(),
                ),
                value: _selectedNatureOfProblem,
                onChanged: (value) {
                  setState(() {
                    _selectedNatureOfProblem = value;
                  });
                },
                items: _natureOfProblems.map((problem) {
                  return DropdownMenuItem<String>(
                    value: problem,
                    child: Text(problem),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedServiceType,
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value;
                  });
                },
                items: _serviceTypes.map((service) {
                  return DropdownMenuItem<String>(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dateAttendedController,
                decoration: const InputDecoration(
                  labelText: 'Date Attended (yyyy-mm-dd)',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode()); // Unfocus
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                      _dateAttendedController.text = "${pickedDate.toLocal()}".split(' ')[0];
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _workDoneController,
                decoration: const InputDecoration(
                  labelText: 'Work Done',
                  border: OutlineInputBorder(),
                ),

              ),
              const SizedBox(height: 16),
              TextField(
                controller: _clientCommentController,
                decoration: const InputDecoration(labelText: 'Client Comment',border: OutlineInputBorder(),),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage('carPlateNumber_picture'),
                    child: const Text('Pick Car Plate Number Image'),
                  ),
                  if (_carPlateNumberImage != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage('tampering_evidence_picture'),
                    child: const Text('Pick Tampering Evidence Image'),
                  ),
                  if (_tamperingEvidenceImage != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage('pre_workdone_picture'),
                    child: const Text('Pick Pre Work Done Image'),
                  ),
                  if (_preWorkDoneImage != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage('post_workdone_picture'),
                    child: const Text('Pick Post Work Done Image'),
                  ),
                  if (_postWorkDoneImage != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitJobCard,
                child: const Text('Submit Job Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
