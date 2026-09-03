import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ufid/ufid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UFID Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UfidHomeScreen(),
    );
  }
}

class UfidHomeScreen extends StatefulWidget {
  const UfidHomeScreen({super.key});

  @override
  State<UfidHomeScreen> createState() => _UfidHomeScreenState();
}

class _UfidHomeScreenState extends State<UfidHomeScreen> {
  String? _ufid;
  bool? _isReinstalled;
  String _platformVersion = 'Unknown';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUfidData();
  }

  Future<void> _loadUfidData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final platformVersion = await Ufid.getPlatformVersion() ?? 'Unknown';
      final info = await Ufid.getInfo();

      if (!mounted) return;

      setState(() {
        _platformVersion = platformVersion;
        _ufid = info.ufid;
        _isReinstalled = info.isReinstalled;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'PlatformException: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetUfidState() async {
    try {
      final success = await Ufid.reset();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Reset successful!' : 'Reset returned false.',
          ),
        ),
      );

      await _loadUfidData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset: $e')),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied UFID to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UFID Demo App'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Card(
                      color: Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildUfidCard(),
                  const SizedBox(height: 16),
                  _buildPlatformCard(),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loadUfidData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Info'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _resetUfidState,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Reset UFID State (Debug)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isReinstalled = _isReinstalled ?? false;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Installation Status',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isReinstalled ? Icons.replay : Icons.fiber_new,
                  color: isReinstalled ? Colors.orange : Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isReinstalled ? 'RE-INSTALLED' : 'FIRST-TIME INSTALL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isReinstalled ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isReinstalled
                  ? 'This app was previously installed on this device and has now been re-installed.'
                  : 'This is the very first time this app is running on this device.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUfidCard() {
    final ufid = _ufid ?? 'N/A';
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Follow ID (UFID)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SelectableText(
              ufid,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copyToClipboard(ufid),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Version',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              _platformVersion,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
