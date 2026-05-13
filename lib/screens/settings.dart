import 'package:flutter/material.dart';
import 'package:fjkm_kajy/screens/change-pin.dart';
import 'package:fjkm_kajy/services/import_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.indigo,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: AppBar(
        title: const Text("Paramètres"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          _buildTile(
            icon: Icons.lock,
            title: "Modifier le PIN",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePinPage()),
              );
            },
          ),

          const Divider(),

          _buildTile(
            icon: Icons.upload_file,
            title: "Importer des données",
            color: Colors.green,
            onTap: () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Importer"),
                  content: const Text(
                    "Importer va ajouter des données. Continuer ?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Annuler"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Importer"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ImportService.importFile();
              }
            },
          ),
        ],
      ),
    );
  }
}
