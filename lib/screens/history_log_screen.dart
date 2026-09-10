import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryLogScreen extends StatelessWidget {
  const HistoryLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference historyRef =
        FirebaseDatabase.instance.ref('gas_leak_history');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gas Leakage History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_sweep,
              color: Colors.white,
            ),
            tooltip: 'Clear History',
            onPressed: () async {
              await historyRef.remove();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('History log cleared.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: historyRef.onValue,
        builder: (
          context,
          AsyncSnapshot<DatabaseEvent> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data =
              snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;

          if (data == null || data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No gas leakage incidents recorded yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final List<Map<String, dynamic>> logs = [];

          data.forEach((key, value) {
            logs.add({
              'id': key,
              'ppm_level': value['ppm_level'] ?? 0,
              'timestamp': value['timestamp'] ?? 'N/A',
              'status': value['status'] ?? 'DANGER',
            });
          });

          logs.sort(
            (a, b) =>
                b['timestamp'].compareTo(a['timestamp']),
          );

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(
                  vertical: 6.0,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.warning,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'Gas Leakage Detected (${log['ppm_level']} PPM)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Time: ${log['timestamp']}',
                  ),
                  trailing: const Chip(
                    label: Text(
                      'DANGER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    backgroundColor: Colors.red,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}