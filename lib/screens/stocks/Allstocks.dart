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
import '../device_returns/Index.dart';

class Allstocks extends StatefulWidget {
  const Allstocks({super.key});

  @override
  _AllstocksState createState() => _AllstocksState();
}

class _AllstocksState extends State<Allstocks> {
  String userEmail = 'Loading...';
  bool isLoading = true;
  final storage = const FlutterSecureStorage();

  int masterCount = 0;
  int iButtonCount = 0;
  int buzzerCount = 0;
  int panickButtonCount = 0;
  int totalDevicesCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _fetchDeviceCounts();
  }

  Future<void> _fetchUserEmail() async {
    try {
      final token = await storage.read(key: 'token');
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

  Future<void> _logout() async {
    try {
      final token = await storage.read(key: 'token');
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
        await storage.delete(key: 'token');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthenticationPage()),
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

  Future<void> _fetchDeviceCounts() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return;

      final urls = {
        'master': 'http://192.168.100.105:8000/api/count/master',
        'i_button': 'http://192.168.100.105:8000/api/count/i_button',
        'buzzer': 'http://192.168.100.105:8000/api/count/buzzer',
        'panick_button': 'http://192.168.100.105:8000/api/count/panick_button',
        'total': 'http://192.168.100.105:8000/api/count/total',
      };

      final responses = await Future.wait([
        http.get(Uri.parse(urls['master']!), headers: {'Authorization': 'Bearer $token'}),
        http.get(Uri.parse(urls['i_button']!), headers: {'Authorization': 'Bearer $token'}),
        http.get(Uri.parse(urls['buzzer']!), headers: {'Authorization': 'Bearer $token'}),
        http.get(Uri.parse(urls['panick_button']!), headers: {'Authorization': 'Bearer $token'}),
        http.get(Uri.parse(urls['total']!), headers: {'Authorization': 'Bearer $token'}),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        setState(() {
          masterCount = json.decode(responses[0].body)['master_count'];
          iButtonCount = json.decode(responses[1].body)['i_button_count'];
          buzzerCount = json.decode(responses[2].body)['buzzer_count'];
          panickButtonCount = json.decode(responses[3].body)['panick_button_count'];
          totalDevicesCount = json.decode(responses[4].body)['total_devices'];
        });
      }
    } catch (error) {
      print('Error fetching device counts: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stocks',style: TextStyle(
          fontSize: 15.0,
        ),),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildDeviceCountCard('Master', masterCount),
              const SizedBox(height: 10),
              _buildDeviceCountCard('I Button', iButtonCount),
              const SizedBox(height: 10),
              _buildDeviceCountCard('Buzzer', buzzerCount),
              const SizedBox(height: 10),
              _buildDeviceCountCard('Panick Button', panickButtonCount),
              const SizedBox(height: 10),
              _buildDeviceCountCard('Total Devices', totalDevicesCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14.0,
          fontFamily: 'EuclidCircularA',
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDeviceCountCard(String title, int count) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
