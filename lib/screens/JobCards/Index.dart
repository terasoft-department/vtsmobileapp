import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Dashboard.dart';
import '../Login.dart';
import '../Requsitions/Index.dart';
import '../UserProfile.dart';
import '../assiginments/Assignments.dart';
import '../assiginments/History.dart';
import '../check_lists/CheckLists.dart';
import '../device_returns/Index.dart';
import '../stocks/Allstocks.dart';
import 'AddJobCard.dart';

class Jobcards extends StatefulWidget {
  const Jobcards({super.key});

  @override
  _JobcardsState createState() => _JobcardsState();
}

class _JobcardsState extends State<Jobcards> {
  String userEmail = 'Loading...';
  bool isLoading = true;
  bool isFetchingData = false;
  List<dynamic> jobCards = [];
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _fetchJobCards();
  }

  Future<void> _fetchUserEmail() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        if (mounted) {
          setState(() {
            userEmail = 'Token not found';
            isLoading = false;
          });
        }
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
        if (mounted) {
          setState(() {
            userEmail = jsonResponse['name'] ?? 'No Name Available'; // Handle null case
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userEmail = 'Error fetching name';
            isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          userEmail = 'An error occurred';
          isLoading = false;
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


  Future<void> _fetchJobCards() async {
    setState(() {
      isFetchingData = true;
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        if (mounted) {
          setState(() {
            isFetchingData = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.100.105:8000/api/jobcards'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (mounted) {
          setState(() {
            jobCards = jsonResponse['job_cards'] ?? [];
            isFetchingData = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            jobCards = [];
            isFetchingData = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          jobCards = [];
          isFetchingData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('JobCards', style: TextStyle(fontSize: 15.0)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchJobCards,
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
      body: isFetchingData
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Button with blue background (appears once)
          const SizedBox(height: 9.0,),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddJobCard(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Background color (blue)
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
            child: const Text(
              'Submit Job Card',
              style: TextStyle(color: Colors.white),
            ),
          ),
          // Spacing between the button and the job cards list
          const SizedBox(height: 10.0),
          Expanded(
            child: jobCards.isEmpty
                ? const Center(child: Text('No job card available'))
                : ListView.builder(
              itemCount: jobCards.length,
              itemBuilder: (context, index) {
                final jobCard = jobCards[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 1.0,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Card ID: ${jobCard['jobcard_id']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Customername: ${jobCard['customername']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Device Number: ${jobCard['imei_number']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Car PlateNumber: ${jobCard['plate_number']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            'Contact Person: ${jobCard['contact_person']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Mobile: ${jobCard['mobile_number']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Location: ${jobCard['physical_location']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Problem Reported: ${jobCard['problem_reported']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Nature of Problem: ${jobCard['natureOf_ProblemAt_site']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Service Type: ${jobCard['service_type']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Date Attended: ${jobCard['date_attended']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Work Done: ${jobCard['work_done']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Client Comment: ${jobCard['client_comment']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          _buildImageSection(
                            'Pre-Workdone Picture',
                            jobCard['pre_workdone_picture'],
                          ),
                          _buildImageSection(
                            'Post-Workdone Picture',
                            jobCard['post_workdone_picture'],
                          ),
                          _buildImageSection(
                            'Car Plate Number Picture',
                            jobCard['carPlateNumber_picture'],
                          ),
                          _buildImageSection(
                            'Tampering Evidence Picture',
                            jobCard['tampering_evidence_picture'],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Function to build images
  Widget _buildImageSection(String title, String? imageUrl) { // Make imageUrl nullable
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        imageUrl != null && imageUrl.isNotEmpty // Check for null and empty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 150, // Adjusted height for images
            fit: BoxFit.cover, // Maintain aspect ratio
          ),
        )
            : const Text('No Image Available'),
        const SizedBox(height: 16), // Add spacing between sections
      ],
    );
  }
}
