import 'package:flutter/material.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuel_station.dart'; // Make sure this import is correct

class FuelEfficiencyTips extends StatelessWidget {
  const FuelEfficiencyTips({Key? key}) : super(key: key);

  void _showSubmitTipDialog(BuildContext context, FirestoreService firestoreService) {
    final TextEditingController _tipController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Submit a Fuel Efficiency Tip'),
          content: TextFormField(
            controller: _tipController,
            decoration: InputDecoration(hintText: 'Enter your tip here'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                if (_tipController.text.isNotEmpty) {
                  firestoreService.addFuelEfficiencyTip(_tipController.text);
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
        title: Text('Fuel Efficiency Tips'),
        backgroundColor: Colors.green[100],
      ),
      body: StreamBuilder<List<FuelEfficiencyTip>>(
        stream: _firestoreService.streamFuelEfficiencyTips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tips available'));
          }

          List<FuelEfficiencyTip> tips = snapshot.data!;

          return ListView.builder(
            itemCount: tips.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.all(8.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green[50], // Light green background color
                  border: Border.all(color: Colors.green, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  title: Text(tips[index].tip),
                  subtitle: Text('Posted on: ${tips[index].timestamp}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubmitTipDialog(context, _firestoreService),
        tooltip: 'Add Tip',
        child: Icon(Icons.add),
      ),
    );
  }
}
