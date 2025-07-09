import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:sidewalk_analysis_frontend/models/width_response.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  // Form controllers
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _headingController = TextEditingController(text: '0');
  final _pitchController = TextEditingController(text: '0');
  final _fovController = TextEditingController(text: '90');
  final _fallbackScaleController = TextEditingController();

  // Form state
  bool _useCoordinates = false;
  bool _refine = true;
  bool _forceFallback = true;
  bool _returnMask = false;

  // API response
  WidthResp? _result;
  bool _isLoading = false;
  String? _error;

  // API base URL (update with your actual API URL)
  static const String baseUrl = 'http://127.0.0.1:8000/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sidewalk Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Type Selector
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _useCoordinates,
                  onChanged: (value) => setState(() => _useCoordinates = false),
                ),
                const Text('Address'),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: true,
                  groupValue: _useCoordinates,
                  onChanged: (value) => setState(() => _useCoordinates = true),
                ),
                const Text('Coordinates'),
              ],
            ),

            // Address Input
            if (!_useCoordinates) ...[
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g., Av. Paulista 1578, São Paulo',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Coordinate Inputs
            if (_useCoordinates) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _lonController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _headingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Heading (0-359)'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _pitchController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pitch (-90-90)'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _fovController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'FOV (10-120)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Options Section
            const Divider(),
            const Text('Processing Options:', style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('Refine Geometry'),
              value: _refine,
              onChanged: (value) => setState(() => _refine = value!),
            ),
            CheckboxListTile(
              title: const Text('Force Fallback'),
              value: _forceFallback,
              onChanged: (value) => setState(() => _forceFallback = value!),
            ),
            CheckboxListTile(
              title: const Text('Return Mask Images'),
              value: _returnMask,
              onChanged: (value) => setState(() => _returnMask = value!),
            ),
            TextField(
              controller: _fallbackScaleController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fallback Scale (optional)',
                hintText: 'metres-per-pixel',
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Analyse Location'),
              ),
            ),

            // Error Display
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Results Display
            if (_result != null) ...[
              const Divider(height: 40),
              const Text('Results:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Text('Sidewalk Width: ${_result!.width_m.toStringAsFixed(2)} meters'),
              Text('Clear Margin: ${_result!.margin_m.toStringAsFixed(2)} meters'),
              const SizedBox(height: 24),

              // Images Display
              if (_returnMask && _result!.hasImages) ...[
                const Text('Street View:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildImage(_result!.gsv_png_b64),
                const SizedBox(height: 16),
                const Text('Sidewalk Mask:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildImage(_result!.mask_png_b64),
                const SizedBox(height: 16),
                const Text('Overlay:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildImage(_result!.overlay_png_b64),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? base64Image) {
    if (base64Image == null) return const Text('No image available');
    return Image.memory(
      base64.decode(base64Image),
      fit: BoxFit.contain,
    );
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      // Prepare request body
      final body = {
        'refine': _refine,
        'force_fallback': _forceFallback,
        'return_mask': _returnMask,
        if (_fallbackScaleController.text.isNotEmpty)
          'fallback_scale': double.parse(_fallbackScaleController.text),
      };

      // Add location data
      if (_useCoordinates) {
        body.addAll({
          'lat': double.parse(_latController.text),
          'lon': double.parse(_lonController.text),
          'heading': int.parse(_headingController.text),
          'pitch': int.parse(_pitchController.text),
          'fov': int.parse(_fovController.text),
        });
      } else {
        body['address'] = _addressController.text;
      }

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/analyse'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      // Handle response
      if (response.statusCode == 200) {
        setState(() {
          _result = WidthResp.fromJson(json.decode(response.body));
        });
      } else {
        setState(() {
          _error = 'API Error (${response.statusCode}): ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
