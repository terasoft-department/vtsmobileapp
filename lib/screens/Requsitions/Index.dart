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
import 'AddRequsition.dart';

class Requisitions extends StatefulWidget {
  const Requisitions({super.key});

  @override
  _RequisitionsState createState() => _RequisitionsState();
}

class _RequisitionsState extends State<Requisitions> {
  final storage = FlutterSecureStorage();
  List<dynamic> requisitions = [];
  List<dynamic> filteredRequisitions = [];
  bool isFetchingData = true;
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRequisitions();
  }

  Future<void> _fetchRequisitions() async {
    setState(() {
      isFetchingData = true;
    });

    try {
      final token = await storage.read(key: 'token'); // Read token from FlutterSecureStorage

      if (token == null) {
        setState(() {
          isFetchingData = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.100.105:8000/api/device-requisitions'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          requisitions = jsonResponse['requisitions'] ?? [];
          // Default status to 'pending' if not present
          requisitions.forEach((req) {
            req['status'] = req['status'] ?? 'pending';
          });
          filteredRequisitions = requisitions;
          isFetchingData = false;
        });
      } else {
        setState(() {
          requisitions = [];
          filteredRequisitions = [];
          isFetchingData = false;
        });
      }
    } catch (error) {
      setState(() {
        requisitions = [];
        filteredRequisitions = [];
        isFetchingData = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final token = await storage.read(key: 'token'); // Read token from FlutterSecureStorage

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No token found')),
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


  void _filterRequisitions(String query) {
    setState(() {
      searchQuery = query;
      filteredRequisitions = requisitions.where((requisition) {
        return requisition['master'].toString().toLowerCase().contains(query.toLowerCase()) ||
            requisition['I_button'].toString().toLowerCase().contains(query.toLowerCase()) ||
            requisition['buzzer'].toString().toLowerCase().contains(query.toLowerCase()) ||
            requisition['panick_button'].toString().toLowerCase().contains(query.toLowerCase()) ||
            requisition['status'].toString().toLowerCase().contains(query.toLowerCase()) ||
            requisition['description'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _navigateToAddRequisition() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddRequisition(),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      isFetchingData = true;
    });
    await _fetchRequisitions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requisitions',style: TextStyle(
          fontSize: 15.0,
        ),),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
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
                    builder: (context) => CheckLists(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment_return),
              title: Text('Returns',style:
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
              leading: Icon(Icons.logout),
              title: Text('Logout',style:
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: isFetchingData
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            SizedBox(height: 9.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align to the right
              children: [
                ElevatedButton(
                  onPressed: _navigateToAddRequisition,
                  child: Text(
                    'Create Requisition',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontFamily: 'EuclidCircularA',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,   // Background color
                    foregroundColor: Colors.white,  // Text color
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.0,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Master, I_button, Buzzer, Panick Button, Status, or Description',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterRequisitions,
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            Expanded(
              child: filteredRequisitions.isEmpty
                  ? Center(child: Text('No requisitions found'))
                  : ListView.builder(
                itemCount: filteredRequisitions.length,
                itemBuilder: (context, index) {
                  final requisition = filteredRequisitions[index];
                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Master: ${requisition['master']}'),
                          Text('I_button: ${requisition['I_button']}'),
                          Text('Buzzer: ${requisition['buzzer']}'),
                          Text('Panick Button: ${requisition['panick_button']}'),
                          Text('Status: ${requisition['status'] ?? 'pending' }',style: TextStyle(
                            color: Colors.green,fontWeight: FontWeight.bold,
                          ),),
                          Text('Description: ${requisition['descriptions'] ?? 'No description available'}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
