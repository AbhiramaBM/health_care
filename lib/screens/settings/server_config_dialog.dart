import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _apiUrlController;
  late final TextEditingController _socketUrlController;
  late final TextEditingController _socketNsController;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController(text: AppConfig.apiBaseUrl);
    _socketUrlController =
        TextEditingController(text: AppConfig.socketServerUrl);
    _socketNsController =
        TextEditingController(text: AppConfig.socketNamespace);
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _socketUrlController.dispose();
    _socketNsController.dispose();
    super.dispose();
  }

  void _save() {
    AppConfig.updateConfig(
      baseUrl: _apiUrlController.text.trim(),
      socketUrl: _socketUrlController.text.trim(),
      socketNs: _socketNsController.text.trim(),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server endpoints updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Server Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configure the backend REST API and Socket.IO endpoints.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'e.g. https://api.myclinic.com',
                prefixIcon: Icon(Icons.http),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _socketUrlController,
              decoration: const InputDecoration(
                labelText: 'Socket Server URL',
                hintText: 'e.g. https://socket.myclinic.com',
                prefixIcon: Icon(Icons.cable),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _socketNsController,
              decoration: const InputDecoration(
                labelText: 'Socket Namespace',
                hintText: 'e.g. / or /chat',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
