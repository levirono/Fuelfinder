import 'package:flutter/material.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuel_station.dart';

class FuelEfficiencyTips extends StatelessWidget {
  const FuelEfficiencyTips({Key? key}) : super(key: key);

  void _showSubmitTipDialog(BuildContext context, FirestoreService firestoreService) {
    final TextEditingController tipController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submit a Fuel Efficiency Tip', style: TextStyle(fontSize: 20.0, color: Colors.green)),
          content: TextFormField(
            controller: tipController,
            decoration: const InputDecoration(
              hintText: 'Enter your tip here',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Submit', style: TextStyle(color: Colors.green)),
              onPressed: () {
                if (tipController.text.isNotEmpty) {
                  firestoreService.addFuelEfficiencyTip(tipController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Efficiency Tips', style: TextStyle(fontSize: 30.0, color: Colors.green)),
        backgroundColor: Colors.green[100],
      ),
      body: StreamBuilder<List<FuelEfficiencyTip>>(
        stream: _firestoreService.streamFuelEfficiencyTips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tips available', style: TextStyle(color: Colors.grey)));
          }

          List<FuelEfficiencyTip> tips = snapshot.data!;

          return ListView.builder(
            itemCount: tips.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3), 
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(tips[index].tip, style: const TextStyle(color: Colors.green, fontSize: 16.0)),
                  subtitle: Text('Posted on: ${tips[index].timestamp}', style: const TextStyle(color: Colors.grey)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubmitTipDialog(context, _firestoreService),
        tooltip: 'Add Tip',
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
