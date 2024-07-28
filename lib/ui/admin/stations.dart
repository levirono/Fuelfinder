import 'package:flutter/material.dart';
import 'package:ff_main/models/fuelfinder.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'STATIONS',
          style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.green[800]),
        ),
        backgroundColor: Colors.green[100],
      ),
      body: SafeArea(
        child: StreamBuilder<List<FuelStation>>(
          stream: _firestoreService.streamStations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No stations available', style: TextStyle(color: Colors.grey)));
            } else {
              final stations = snapshot.data!;
              return ListView.builder(
                itemCount: stations.length,
                itemBuilder: (context, index) {
                  final station = stations[index];
                  return StationListItem(
                    key: ValueKey(station.id),
                    station: station,
                    userRole: _userRole,
                    onDelete: _deleteStation,
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class StationListItem extends StatefulWidget {
  final FuelStation station;
  final String? userRole;
  final Function(String) onDelete;

  const StationListItem({
    Key? key,
    required this.station,
    required this.userRole,
    required this.onDelete,
  }) : super(key: key);

  @override
  StationListItemState createState() => StationListItemState();
}

class StationListItemState extends State<StationListItem> {
  late bool isVerified;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    isVerified = widget.station.isVerified;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StationServices>(
      future: _firestoreService.getStationServices(widget.station.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListTile(widget.station.name, 'Loading...', Colors.grey);
        }
        if (snapshot.hasError) {
          return _buildListTile(widget.station.name, 'Data unavailable', Colors.grey);
        }
        final services = snapshot.data!;
        return _buildStationTile(context, services);
      },
    );
  }

  Widget _buildStationTile(BuildContext context, StationServices services) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FuelStationDetailsPage(station: widget.station),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                    Expanded(
                      child: Text(
                        widget.station.name,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (widget.userRole == 'admin') ...[
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool confirmDelete = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.green[100],
                              title: const Text('Delete Station'),
                              content: const Text(
                                  'Are you sure you want to delete this station?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel',
                                    style: TextStyle(
                                      color: Colors.orange
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmDelete) {
                            widget.onDelete(widget.station.id);
                          }
                        },
                      ),
                      _buildVerificationButton(),
                    ]
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.location_on),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Location: ${widget.station.location}',
                        style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
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
  }

  Widget _buildVerificationButton() {
    return IconButton(
      icon: Icon(
        isVerified ? Icons.verified : Icons.verified_outlined,
        color: isVerified ? Colors.blue : Colors.grey,
      ),
      onPressed: () async {
        bool newStatus = !isVerified;
        bool success = await _firestoreService.updateStationVerificationStatus(widget.station.id, newStatus);
        if (success) {
          setState(() {
            isVerified = newStatus;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update verification status')),
          );
        }
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
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}