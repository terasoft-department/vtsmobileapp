import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vtsmobileapp/screens/stocks/Allstocks.dart';
import 'JobCards/Index.dart';
import 'Login.dart';
import 'Requsitions/Index.dart';
import 'UserProfile.dart';
import 'assiginments/Assignments.dart';
import 'assiginments/History.dart';
import 'check_lists/CheckLists.dart';
import 'device_returns/Index.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String userEmail = 'Loading...';
  String assignmentsCount = 'Loading...';
  String requisitionsCount = 'Loading...';
  String jobCardsCount = 'Loading...';
  bool isLoading = true;
  final storage = const FlutterSecureStorage(); // Initialize FlutterSecureStorage

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _fetchCounts();
  }

  Future<void> _fetchUserEmail() async {
    try {
      final token = await storage.read(key: 'token'); // Read token from FlutterSecureStorage

      if (token == null) {
        setState(() {
          userEmail = 'Token not found';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.100.105:8000/api/get_login_user'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          userEmail = jsonResponse['name'];
          isLoading = false;
        });
      } else {
        setState(() {
          userEmail = 'Error fetching name';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        userEmail = 'An error occurred';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCounts() async {
    try {
      final token = await storage.read(key: 'token'); // Read token from FlutterSecureStorage

      if (token == null) {
        setState(() {
          // Handle token not found scenario
          isLoading = false;
        });
        return;
      }

      final responses = await Future.wait([
        http.get(
          Uri.parse('http://192.168.100.105:8000/api/countAssign'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('http://192.168.100.105:8000/api/countRequisitions'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('http://192.168.100.105:8000/api/countJobCards'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        final assignmentCount = json.decode(responses[0].body)['count'];
        final requisitionCount = json.decode(responses[1].body)['count'];
        final jobCardCount = json.decode(responses[2].body)['count'];

        setState(() {
          // Update state with fetched counts
          assignmentsCount = assignmentCount.toString();
          requisitionsCount = requisitionCount.toString();
          jobCardsCount = jobCardCount.toString();
          isLoading = false;
        });
      } else {
        setState(() {
          // Handle error fetching counts
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        // Handle any other errors
        isLoading = false;
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
        SnackBar(content: Text('An error occurred during logout')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isLoading ? const Text('Welcome',style:
        (TextStyle(
          fontSize: 15.0,
        )),) : Text('Welcome: $userEmail',style: (
        const TextStyle(
          fontSize: 14,
            fontFamily: 'EuclidCircularA',
        )
        ),),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show a loading indicator while loading
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Row of cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildCard('Assignment', assignmentsCount)),
                  const SizedBox(width: 8), // Add spacing between cards
                  Expanded(child: _buildCard('Requisition', requisitionsCount)),
                  const SizedBox(width: 8), // Add spacing between cards
                  Expanded(child: _buildCard('JobCard', jobCardsCount)),
                ],
              ),
              const SizedBox(height: 16), // Space between cards row and image

              // Image below the row of cards
              Image.asset(
                'assets/images/logo.png', // Update this if you have a different image path
                width: 100,
                height: 100,
              ), // Space between image and new row
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
    );
  }

  Widget _buildCard(String header, String body) {
    return Card(
      elevation: 1, // Add a bit more elevation to make it stand out
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Container(
            height: 70.0,
            padding: const EdgeInsets.all(16.0),
            child: Text(
              header,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 14.0,
                fontFamily: 'EuclidCircularA',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              body,
              style: const TextStyle(fontSize: 14.0, fontFamily: 'EuclidCircularA'),
            ),
          ),
        ],
      ),
    );
  }
}
