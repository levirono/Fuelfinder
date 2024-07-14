import 'package:flutter/material.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuelfinder.dart';

class FuelEfficiencyTips extends StatelessWidget {
  const FuelEfficiencyTips({Key? key}) : super(key: key);

  void _showSubmitTipDialog(BuildContext context, FirestoreService firestoreService, {FuelEfficiencyTip? tip}) {
    final TextEditingController tipController = TextEditingController(text: tip?.tip);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tip == null ? 'Submit a Fuel Efficiency Tip' : 'Edit Fuel Efficiency Tip', 
                      style: const TextStyle(fontSize: 20.0, color: Colors.green)),
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
              child: Text(tip == null ? 'Submit' : 'Update', style: const TextStyle(color: Colors.green)),
              onPressed: () {
                if (tipController.text.isNotEmpty) {
                  if (tip == null) {
                    firestoreService.addFuelEfficiencyTip(tipController.text);
                  } else {
                    firestoreService.updateFuelEfficiencyTip(tip.id, tipController.text);
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, FirestoreService firestoreService, String tipId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[100],
          title: const Text('Delete Tip', style: TextStyle(color: Colors.black)),
          content: const Text('Are you sure you want to delete this tip?'),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.amber)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                firestoreService.deleteFuelEfficiencyTip(tipId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Efficiency Tips',
        style: TextStyle(fontSize:30.0,fontWeight: FontWeight.bold,color: Colors.green),
         ),
        backgroundColor: Colors.green[100],
      ),
      body: StreamBuilder<List<FuelEfficiencyTip>>(
        stream: firestoreService.streamFuelEfficiencyTips(),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showSubmitTipDialog(context, firestoreService, tip: tips[index]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmationDialog(context, firestoreService, tips[index].id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubmitTipDialog(context, firestoreService),
        tooltip: 'Add Tip',
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}