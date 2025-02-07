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
  String vehicleNumber = "Loading..."; // Initial state
  String deviceID = "Loading...";
  double batteryLevel = 0; // Default to 0
  String engineStatus = "Fetching..."; // Default to fetching
  LatLng _currentPosition = LatLng(37.4219999, -122.0840575); // Default position

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadVehicleNumber(); // Fetch vehicle number on startup
    _loadDeviceID();
    fetchAntiTheftStatus();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchDataFromServer();
    });
  }
  Future<void> _loadDeviceID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      deviceID = prefs.getString('device_id') ?? "Unknown Device";
    });
  }


  Future<void> _loadVehicleNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      vehicleNumber = prefs.getString('vehicle_number') ?? "Loading...";
    });
  }


  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchVehicleNumber() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/get_vehicle_number'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          vehicleNumber = data['vehicle_number'] ?? "Unknown";
        });
      } else {
        print("Failed to fetch vehicle number");
      }
    } catch (e) {
      print("Error fetching vehicle number: $e");
    }
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
          deviceID = data['device_id'] ?? deviceID;

          // Update vehicleNumber if it exists
          if (data.containsKey('vehicle_number')) {
            vehicleNumber = data['vehicle_number'];
          }
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
  void _addLocation() {
    showDialog(
      context: context,
      builder: (context) {
        String locationName = '';
        double latitude = 0.0;
        double longitude = 0.0;

        return AlertDialog(
          title: Text('Add Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Location Name'),
                onChanged: (value) {
                  locationName = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  latitude = double.tryParse(value) ?? 0.0;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  longitude = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _sendLocationToServer(locationName, latitude, longitude);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendLocationToServer(String name, double lat, double lng) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/add_location'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'latitude': lat,
        'longitude': lng,
      }),
    );

    if (response.statusCode == 201) {
      print('Location added successfully');
    } else {
      print('Failed to add location');
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
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                ).then((value) {
                  if (value != null && value is String) {
                    setState(() {
                      deviceID = value; // Update device ID instantly
                    });
                  }
                });
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
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 250, // Set desired width
                    height: 50, // Set desired height
                    child: Image.asset(
                      'assets/registration-plate.png',
                    ),
                  ),
                  Positioned(
                    left: 108,
                    top: 4, // Adjust this value to position the top text
                    child: Text(
                      vehicleNumber.length > 5 ? vehicleNumber.substring(0, 5) : vehicleNumber,
                      style: TextStyle(
                        fontSize: 17, // Adjust font size as needed
                        color: Colors.black, // Change color as needed
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 23,
                    left: 115,
                    child: Text(
                      vehicleNumber.length > 5 ? vehicleNumber.substring(5) : '',
                      style: TextStyle(
                        fontSize: 17, // Adjust font size as needed
                        color: Colors.black, // Change color as needed
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
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

                  Transform.scale(
                    scale: 0.8, // Adjust the scale factor as needed
                    child: Switch(
                      value: antiTheftMode,
                      onChanged: (value) {
                        updateAntiTheftMode(value); // Update Anti-Theft mode on the server

                      },
                    ),
                  ),
                  const Text("Anti-Theft Mode"),
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
                    zoom: 18.0,
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
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 35.0,
                          height: 35.0,
                          point: _currentPosition, // Updated position
                          builder: (ctx) => Image.asset('assets/pin.png'), // Car Icon
                        ),
                      ],
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
                SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FullMapView()),
                    );
                  },
                  child: const Text("View Map📍"),
                ),
                SizedBox(width: 4), // Add space between buttons
                ElevatedButton(
                  onPressed: _addLocation,
                  child: Text("Add Geo-Fence"),
                ),
                SizedBox(width: 4), // Add space between buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RoutesLogPage(deviceID: deviceID)),
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
class RoutesLogPage extends StatefulWidget {
  final String deviceID;

  const RoutesLogPage({Key? key, required this.deviceID}) : super(key: key);

  @override
  _RoutesLogPageState createState() => _RoutesLogPageState();
}

class _RoutesLogPageState extends State<RoutesLogPage> {
  List<dynamic> logs = [];

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/logs'));

    if (response.statusCode == 200) {
      setState(() {
        logs = json.decode(response.body)['logs'];
      });
    } else {
      // Handle error
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Route Logs"),
        centerTitle: true,
        backgroundColor: Colors.purple[200],
      ),
      body: logs.isEmpty
          ? Center(
        child: Text(
          "No logs available",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      )
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: DataTable(
            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.black!),
            columns: [
              DataColumn(label: Text("Location", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Engine Status", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("AT Mode", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: logs.map((log) {
              return DataRow(cells: [
                DataCell(Text("${log['latitude']}, ${log['longitude']}", style: TextStyle(color: Colors.black87))),
                DataCell(Text(log['engine_status'], style: TextStyle(color: log['engine_status'] == 'On' ? Colors.green : Colors.red))),
                DataCell(Text(log['anti_theft'] ? "On" : "Off", style: TextStyle(color: log['anti_theft'] ? Colors.green : Colors.red))),
                DataCell(
                  IconButton(
                    icon: Icon(Icons.remove_red_eye, color: Colors.blueAccent),
                    onPressed: () {
                      // Implement view location functionality
                    },
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}




class FullMapView extends StatelessWidget {
  final LatLng _currentPosition = LatLng(37.4219999, -122.0840575); // Example position

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Map View"),
        backgroundColor: Colors.purple[200],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Curved corners for map
        child: FlutterMap(
          options: MapOptions(
            center: _currentPosition, // Example position
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
            MarkerLayer(
              markers: [
                Marker(
                  width: 35.0,
                  height: 35.0,
                  point: _currentPosition, // Updated position
                  builder: (ctx) => Image.asset('assets/pin.png'), // Car Icon
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchVehicleNumber();
    _fetchDeviceID();
  }
  Future<void> _fetchDeviceID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/get_device_id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _deviceIdController.text = data['device_id'] ?? '';
      }
    } catch (e) {
      print('Error fetching device ID: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDeviceID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/update_device_id'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'device_id': _deviceIdController.text}),
      );

      if (response.statusCode == 200) {
        await prefs.setString('device_id', _deviceIdController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Device ID updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Update failed')),
        );
      }
    } catch (e) {
      print('Error updating Device ID: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchVehicleNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/get_vehicle_number'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _vehicleNumberController.text = data['vehicle_number'] ?? '';
      }
    } catch (e) {
      print('Error fetching vehicle number: $e');
    } finally {
      setState(() => _isLoading = false);
    }

  }
  Future<void> _updatePin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/update_pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'device_id': _deviceIdController.text,
          'pin': _pinController.text,
          'email': _emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Pin updated successfully')),
        );
        Navigator.pop(context); // Go back to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Update failed')),
        );
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _saveChanges() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/update_vehicle_number'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'vehicle_number': _vehicleNumberController.text}),
      );

      if (response.statusCode == 200) {
        // ✅ Save the updated vehicle number to SharedPreferences
        await prefs.setString('vehicle_number', _vehicleNumberController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Vehicle number updated')),
        );

        Navigator.pop(context, _vehicleNumberController.text); // Pass updated value to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Update failed')),
        );
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _deviceIdController,
              decoration: InputDecoration(labelText: "Device ID"),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: _vehicleNumberController,
              decoration: InputDecoration(labelText: "Vehicle Number"),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveChanges,
              child: Text("Save Changes"),
            ),
            TextField(
              controller: _pinController,
              decoration: InputDecoration(labelText: "New Device Pin"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _updatePin,
              child: Text("Update Pin"),
            ),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

