import 'package:flutter/material.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/ui/driver/station_details.dart';

class StationsPage extends StatefulWidget {
  const StationsPage({super.key});

  @override
  StationsPageState createState() => StationsPageState();
}

class StationsPageState extends State<StationsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    _userRole = await _authService.getUserRole();
    setState(() {});
  }

  void _deleteStation(String stationId) async {
    await _firestoreService.deleteStation(stationId);
    setState(() {});
  }

  void _verifyStation(String stationId, bool isVerified) async {
    await _firestoreService.verifyStation(stationId, isVerified);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'STATIONS',
          style: TextStyle(color: Colors.green[800]),
        ),
        backgroundColor: Colors.green[100],
      ),
      body: StreamBuilder<List<FuelStation>>(
        stream: _firestoreService.streamStations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No stations available',
              style: TextStyle(color: Colors.grey),
            ));
          } else {
            final stations = snapshot.data!;
            return ListView.builder(
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                return _buildStationTile(context, station);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildStationTile(BuildContext context, FuelStation station) {
    return FutureBuilder<StationServices>(
      future: _firestoreService.getStationServices(station.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListTile(station.name, 'Loading...', Colors.grey);
        }
        if (snapshot.hasError) {
          return _buildListTile(station.name, 'Data unavailable', Colors.grey);
        }
        final services = snapshot.data!;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FuelStationDetailsPage(station: station),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20.0),
                right: Radius.circular(20.0),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20.0),
                    right: Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_gas_station),
                        const SizedBox(width: 8.0),
                        Text(
                          station.name,
                          style: const TextStyle(
                              color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (_userRole == 'admin') ...[
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              bool confirmDelete = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Station'),
                                  content: const Text(
                                      'Are you sure you want to delete this station?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmDelete) {
                                _deleteStation(station.id);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              station.isVerified
                                  ? Icons.verified
                                  : Icons.verified_outlined,
                              color:
                                  station.isVerified ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () async {
                              _verifyStation(station.id, !station.isVerified);
                            },
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.location_on),  
                        const SizedBox(width: 8.0),
                        Text(
                          'Location: ${station.location}',
                          style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle,
                                color: services.isPetrolAvailable
                                    ? Colors.green
                                    : Colors.red),
                            const SizedBox(width: 4.0),
                            const Text('Petrol'),
                            const SizedBox(width: 16.0),
                            Icon(Icons.circle,
                                color: services.isDieselAvailable
                                    ? Colors.green
                                    : Colors.red),
                            const SizedBox(width: 4.0),
                            const Text('Diesel'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTile(String title, String subtitle, Color backgroundColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
        color: backgroundColor,
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}
