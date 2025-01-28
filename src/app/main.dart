import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(), // Redirect to AuthWrapper to handle login state
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      // Validate the token with the server
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/validate_token'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          isAuthenticated = true;
        });
      } else {
        prefs.remove('token');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isAuthenticated ? GPSHomePage(logoHeight: 50) : LoginPage();
  }
}
class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _register() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': nameController.text,
        'email': emailController.text,
        'number': numberController.text,
        'password': passwordController.text,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 201) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Registration Successful ✅'),
          content: Text('You can now log in with your credentials'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Text('Login'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Registration Failed ❌'),
          content: Text('Something went wrong. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: numberController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GPSHomePage(logoHeight: 50)),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Failed'),
          content: Text('Invalid email or password'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GPS X Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 128,
              height: 80,
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text("Don't have an account, Register here"),
            ),
          ],
        ),
      ),
    );
  }
}

class GPSHomePage extends StatefulWidget {
  final double logoHeight;

  const GPSHomePage({Key? key, required this.logoHeight}) : super(key: key);

  @override
  _GPSHomePageState createState() => _GPSHomePageState();
}

class _GPSHomePageState extends State<GPSHomePage> {
  bool antiTheftMode = false;
  String vehicleNumber = "AS01X XXX23";
  String vehicleID = "1234";
  double batteryLevel = 0; // Default to 0
  String engineStatus = "Fetching..."; // Default to fetching
  LatLng _currentPosition = LatLng(37.4219999, -122.0840575); // Default position

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchAntiTheftStatus(); // Fetch the initial Anti-Theft Mode status from the server
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchDataFromServer();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchDataFromServer() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/fetch_status'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          batteryLevel = data['battery_level'] ?? 0;
          engineStatus = data['engine_status'] ?? "Fetching...";
          double lat = data['latitude'] ?? _currentPosition.latitude;
          double lng = data['longitude'] ?? _currentPosition.longitude;
          _currentPosition = LatLng(lat, lng);
        });
      } else {
        setState(() {
          engineStatus = "Fetching...";
        });
      }
    } catch (e) {
      setState(() {
        engineStatus = "Fetching...";
      });
      print("Error fetching data: $e");
    }
  }

  Future<void> fetchAntiTheftStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/get_anti_theft'),
        headers: {
          'Authorization': 'Bearer <your_jwt_token>', // Replace with your JWT token
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          antiTheftMode = data['anti_theft'] ?? false;
        });
      }
    } catch (e) {
      print("Error fetching Anti-Theft status: $e");
    }
  }

  void updateAntiTheftMode(bool value) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/toggle_anti_theft'),
        headers: {
          'Authorization': 'Bearer <your_jwt_token>', // Replace with your JWT token
        },
        body: json.encode({'anti_theft': value}),
      );

      if (response.statusCode == 200) {
        setState(() {
          antiTheftMode = value;
        });
      } else {
        print('Failed to update Anti-Theft mode');
      }
    } catch (e) {
      print("Error updating Anti-Theft mode: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage(vehicleID: vehicleID)),
                );
              },
            ),
            SizedBox(width: 50), // Optional: Add space between the icon and logo
            Image.asset(
              'assets/logo.png',
              height: widget.logoHeight,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 10)
          ],
        ),
      ),
      body: Column(
        children: [
          Column(
            children: [
              const Text("Made with ❤️ by Himjyoti", style: TextStyle(fontSize: 16)),
              Image.asset('assets/car.png', height: 150),
              Text(vehicleNumber, style: const TextStyle(fontSize: 17)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Icon(Icons.power, color: Colors.orange),
                  const Text("Engine Status"),
                  Text(engineStatus),
                ],
              ),
              Column(
                children: [
                  const Text("Anti-Theft Mode"),
                  Switch(
                    value: antiTheftMode,
                    onChanged: (value) {
                      updateAntiTheftMode(value); // Update Anti-Theft mode on the server
                    },
                  ),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.battery_full),
                  Text("Battery: $batteryLevel%"),
                ],
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(
                    center: _currentPosition,
                    zoom: 14.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                    interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.app',
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FullMapView()),
                    );
                  },
                  child: const Text("View Map 📍"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RoutesLogPage(vehicleID: vehicleID)),
                    );
                  },
                  child: const Text("Routes Log"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class FullMapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Map View"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Curved corners for map
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(37.4219999, -122.0840575), // Example position
            zoom: 14.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag, // Enable zoom and drag
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.app',
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final String vehicleID;

  const SettingsPage({required this.vehicleID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: "Email ID"),
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Vehicle ID"),
              controller: TextEditingController(text: vehicleID),
            ),
            const TextField(
              decoration: InputDecoration(labelText: "Vehicle Number"),
            ),
            ElevatedButton(
              onPressed: () {
                // Save changes
                print("Updating settings...");
              },
              child: const Text("Save Changes"),
            ),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('token'); // Clear the stored token
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                ); // Redirect to LoginPage and clear history
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoutesLogPage extends StatelessWidget {
  final String vehicleID;

  const RoutesLogPage({required this.vehicleID});

  @override
  Widget build(BuildContext context) {
    // Fetch routes dynamically from server
    return Scaffold(
      appBar: AppBar(title: const Text("Routes Log")),
      body: const Center(
        child: Text("Previous Routes will be displayed here"),
      ),
    );
  }
}
