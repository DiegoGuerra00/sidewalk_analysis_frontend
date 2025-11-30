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
  final _pitchController = TextEditingController(text: '-10');
  final _fovController = TextEditingController(text: '90');
  final _fallbackScaleController = TextEditingController();
  final _minClearController = TextEditingController(text: '1.20');

  // Form state
  bool _useCoordinates = false;
  bool _multiView = false;
  bool _refine = true;
  bool _forceFallback = false;
  bool _returnMask = false;
  String _depthBackend = 'zoe';
  String? _zoeVariant;

  // API response
  dynamic _result;
  bool _isLoading = false;
  String? _error;

  // API base URL - Update this to match your deployment
  static const String baseUrl = 'http://127.0.0.1:8000';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sidewalk AI'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analysis Type Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analysis Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Single View'),
                            subtitle: const Text('Analyze one heading'),
                            value: false,
                            groupValue: _multiView,
                            onChanged: (value) =>
                                setState(() => _multiView = false),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Multi View'),
                            subtitle: const Text('Analyze multiple angles'),
                            value: true,
                            groupValue: _multiView,
                            onChanged: (value) =>
                                setState(() => _multiView = true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Input Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: _useCoordinates,
                          onChanged: (value) =>
                              setState(() => _useCoordinates = false),
                        ),
                        const Text('Address'),
                        const SizedBox(width: 20),
                        Radio<bool>(
                          value: true,
                          groupValue: _useCoordinates,
                          onChanged: (value) =>
                              setState(() => _useCoordinates = true),
                        ),
                        const Text('Coordinates'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (!_useCoordinates) ...[
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          hintText: 'e.g., Av. Paulista 1578, São Paulo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                    ],

                    if (_useCoordinates) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.my_location),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _lonController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.place),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Show heading, pitch, and FOV for single view regardless of input type
                    if (!_multiView) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _headingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Heading',
                          hintText: '0-359 degrees',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.explore),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pitchController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Pitch',
                                hintText: '-90 to 90',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _fovController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'FOV',
                                hintText: '10-120',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Depth Backend Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Depth Backend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('ZoeDepth'),
                            subtitle: const Text('Higher accuracy'),
                            value: 'zoe',
                            groupValue: _depthBackend,
                            onChanged: (value) =>
                                setState(() => _depthBackend = value!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('MiDaS'),
                            subtitle: const Text('Faster processing'),
                            value: 'midas',
                            groupValue: _depthBackend,
                            onChanged: (value) =>
                                setState(() => _depthBackend = value!),
                          ),
                        ),
                      ],
                    ),

                    if (_depthBackend == 'zoe') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _zoeVariant,
                        decoration: const InputDecoration(
                          labelText: 'ZoeDepth Variant',
                          border: OutlineInputBorder(),
                          helperText:
                              'Leave as Default unless you need a specific variant',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Default (ZoeD_N)'),
                          ),
                          DropdownMenuItem(
                            value: 'ZoeD_N',
                            child: Text('ZoeD_N - NYU-trained'),
                          ),
                          DropdownMenuItem(
                            value: 'ZoeD_K',
                            child: Text('ZoeD_K - KITTI-trained'),
                          ),
                          DropdownMenuItem(
                            value: 'ZoeD_NK',
                            child: Text('ZoeD_NK - Combined'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _zoeVariant = value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Processing Options Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Processing Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Refine Geometry'),
                      subtitle: const Text(
                        'Use geometric refinement for better accuracy',
                      ),
                      value: _refine,
                      onChanged: (value) => setState(() => _refine = value!),
                    ),
                    CheckboxListTile(
                      title: const Text('Force Fallback'),
                      subtitle: const Text('Use fallback scale estimation'),
                      value: _forceFallback,
                      onChanged: (value) =>
                          setState(() => _forceFallback = value!),
                    ),
                    CheckboxListTile(
                      title: const Text('Return Mask Images'),
                      subtitle: const Text(
                        'Include visualization overlays (slower)',
                      ),
                      value: _returnMask,
                      onChanged: (value) =>
                          setState(() => _returnMask = value!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _fallbackScaleController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Fallback Scale (optional)',
                        hintText: 'metres-per-pixel',
                        border: OutlineInputBorder(),
                        helperText: 'Override automatic scale estimation',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _minClearController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Minimum Clear Width (m)',
                        hintText: '1.20',
                        border: OutlineInputBorder(),
                        helperText: 'ABNT/NBR 9050 minimum clearance threshold',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitRequest,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics),
                label: Text(
                  _isLoading
                      ? 'Analyzing...'
                      : 'Analyse ${_multiView ? 'Multi-View' : 'Single-View'}',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Error Display
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Error: $_error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Results Display
            if (_result != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_result is SingleResp) {
      return _buildSingleResults(_result as SingleResp);
    } else if (_result is MultiResp) {
      return _buildMultiResults(_result as MultiResp);
    } else {
      return const Text('Unknown result type');
    }
  }

  Widget _buildSingleResults(SingleResp result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        const Text(
          'Single View Results',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: 16),

        // Main Metrics Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Width Measurements',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                _buildMetricRow(
                  'Sidewalk Width',
                  '${result.width_m.toStringAsFixed(2)} m',
                  Icons.straighten,
                ),
                _buildMetricRow(
                  'Clear Margin',
                  '${result.margin_m.toStringAsFixed(2)} m',
                  Icons.space_bar,
                ),
              ],
            ),
          ),
        ),

        // Accessibility Card
        if (result.accessibility != null) ...[
          const SizedBox(height: 16),
          Card(
            color: _getAccessibilityColor(result.accessibility!['rating']),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.accessible, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Accessibility Rating',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildMetricRow(
                    'Rating',
                    result.accessibility!['rating'] ?? 'N/A',
                    Icons.star,
                  ),
                  if (result.accessibility!['free_width_m'] != null)
                    _buildMetricRow(
                      'Free Width',
                      '${(result.accessibility!['free_width_m'] as num).toStringAsFixed(2)} m',
                      Icons.check_circle,
                    ),
                  if (result.accessibility!['meets_minimum'] != null)
                    _buildMetricRow(
                      'Meets Minimum',
                      result.accessibility!['meets_minimum'] ? 'Yes' : 'No',
                      result.accessibility!['meets_minimum']
                          ? Icons.check
                          : Icons.close,
                    ),
                ],
              ),
            ),
          ),
        ],

        // Clearances/Obstacles Card
        if (result.clearances.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Detected Obstacles',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...result.clearances.map(
                    (clearance) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clearance.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (clearance.total_m != null)
                            Text(
                              '  Total clearance: ${clearance.total_m!.toStringAsFixed(2)}m',
                            ),
                          if (clearance.L_m != null)
                            Text(
                              '  Left: ${clearance.L_m!.toStringAsFixed(2)}m',
                            ),
                          if (clearance.R_m != null)
                            Text(
                              '  Right: ${clearance.R_m!.toStringAsFixed(2)}m',
                            ),
                          if (clearance.obs_width != null)
                            Text(
                              '  Obstacle width: ${clearance.obs_width!.toStringAsFixed(2)}m',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Images
        if (_returnMask && result.hasImages) ...[
          const SizedBox(height: 24),
          _buildImageSection('Street View', result.gsv_png_b64),
          const SizedBox(height: 16),
          _buildImageSection(
            'Sidewalk Overlay',
            result.overlay_sidewalk_png_b64,
          ),
          const SizedBox(height: 16),
          _buildImageSection(
            'Obstacle Overlay',
            result.overlay_obstacle_png_b64,
          ),
        ],
      ],
    );
  }

  Widget _buildMultiResults(MultiResp result) {
    // Check if we're on a wider screen (desktop/tablet)
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        const Text(
          'Multi View Results',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: 16),

        // Metadata and Overall Summary in a row on wide screens
        if (isWideScreen)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Metadata Card
                if (result.multi_metadata != null &&
                    result.multi_metadata!['n_headings'] != null)
                  Expanded(child: _buildMetadataCard(result.multi_metadata!)),
                if (result.multi_metadata != null &&
                    result.multi_metadata!['n_headings'] != null &&
                    result.all_views != null)
                  const SizedBox(width: 16),
                // Overall Summary Card
                if (result.all_views != null)
                  Expanded(child: _buildOverallSummaryCard(result.all_views!)),
              ],
            ),
          )
        else ...[
          // Stack vertically on narrow screens
          if (result.multi_metadata != null &&
              result.multi_metadata!['n_headings'] != null) ...[
            _buildMetadataCard(result.multi_metadata!),
            const SizedBox(height: 16),
          ],
          if (result.all_views != null) ...[
            _buildOverallSummaryCard(result.all_views!),
            const SizedBox(height: 16),
          ],
        ],

        if (isWideScreen &&
            (result.multi_metadata != null || result.all_views != null))
          const SizedBox(height: 16),

        // Per Side Results in a row on wide screens
        if (result.per_side != null) ...[
          if (isWideScreen)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (result.per_side!['LEFT'] != null)
                    Expanded(
                      child: _buildSideCard('LEFT', result.per_side!['LEFT']!),
                    ),
                  if (result.per_side!['LEFT'] != null &&
                      result.per_side!['RIGHT'] != null)
                    const SizedBox(width: 16),
                  if (result.per_side!['RIGHT'] != null)
                    Expanded(
                      child: _buildSideCard(
                        'RIGHT',
                        result.per_side!['RIGHT']!,
                      ),
                    ),
                ],
              ),
            )
          else
            ...result.per_side!.entries.map((entry) {
              return Column(
                children: [
                  _buildSideCard(entry.key, entry.value),
                  const SizedBox(height: 16),
                ],
              );
            }),
        ],

        // Sample Images
        if (_returnMask) ...[
          if (result.samples_left != null && result.samples_left!.isNotEmpty ||
              result.samples_right != null &&
                  result.samples_right!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sample Images',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildImageGrid(result.samples_left, result.samples_right),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildMetadataCard(Map<String, dynamic> metadata) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis Coverage',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            _buildMetricRow(
              'Left Side Views',
              '${metadata['n_headings']['left']}',
              Icons.chevron_left,
            ),
            _buildMetricRow(
              'Right Side Views',
              '${metadata['n_headings']['right']}',
              Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummaryCard(Map<String, dynamic> allViews) {
    return Card(
      color: _getAccessibilityColor(allViews['corridor']?['rating']),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Overall Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            if (allViews['corridor'] != null) ...[
              _buildMetricRow(
                'Corridor Rating',
                allViews['corridor']['rating'] ?? 'N/A',
                Icons.star,
              ),
              if (allViews['corridor']['median_m'] != null)
                _buildMetricRow(
                  'Median Free Width',
                  '${(allViews['corridor']['median_m'] as num).toStringAsFixed(2)} m',
                  Icons.straighten,
                ),
              if (allViews['corridor']['meets_ratio'] != null)
                _buildMetricRow(
                  'Compliance Rate',
                  '${((allViews['corridor']['meets_ratio'] as num) * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
            ],
            if (allViews['typical_obstacles_per_view'] != null)
              _buildMetricRow(
                'Average Obstacles per View',
                '${allViews['typical_obstacles_per_view']}',
                Icons.warning,
              ),
            if (allViews['width_range_m'] != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              _buildWidthRangeVisual(
                allViews['width_range_m']['min_m'] as num,
                allViews['width_range_m']['max_m'] as num,
                null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSideCard(String side, MultiSideSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  side == 'LEFT' ? Icons.chevron_left : Icons.chevron_right,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '$side Side',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),

            // Width metrics
            if (summary.median_width != null) ...[
              const Text(
                'Width Measurements',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 4),
              _buildMetricRow(
                'Median Width',
                '${(summary.median_width!['width_m'] as num).toStringAsFixed(2)} m',
                Icons.straighten,
              ),
              _buildMetricRow(
                'Median Margin',
                '${(summary.median_width!['margin_m'] as num).toStringAsFixed(2)} m',
                Icons.space_bar,
              ),
            ],

            // Width range
            if (summary.width_range_m != null) ...[
              const SizedBox(height: 8),
              _buildWidthRangeVisual(
                summary.width_range_m!['min_m'] as num,
                summary.width_range_m!['max_m'] as num,
                summary.median_width?['width_m'] as num?,
              ),
            ],

            // Corridor info
            if (summary.corridor != null) ...[
              const Divider(),
              const Text(
                'Accessibility',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 4),
              if (summary.corridor!.rating != null)
                _buildMetricRow(
                  'Rating',
                  summary.corridor!.rating!,
                  Icons.star,
                ),
              if (summary.corridor!.median_m != null)
                _buildMetricRow(
                  'Median Free Width',
                  '${summary.corridor!.median_m!.toStringAsFixed(2)} m',
                  Icons.check,
                ),
              if (summary.corridor!.meets_ratio != null)
                _buildMetricRow(
                  'Compliance',
                  '${(summary.corridor!.meets_ratio! * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
            ],

            // Obstacles
            if (summary.obstacles != null) ...[
              const Divider(),
              const Text(
                'Obstacles',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 4),
              if (summary.obstacles!.typical_obstacles_per_view != null)
                _buildMetricRow(
                  'Typical per View',
                  '${summary.obstacles!.typical_obstacles_per_view}',
                  Icons.warning,
                ),

              // Obstacle types breakdown
              if (summary.obstacles!.types != null &&
                  summary.obstacles!.types!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Obstacle Types:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                ...summary.obstacles!.types!.entries.map((type) {
                  final typeData = type.value as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '${type.key}: ${((typeData['prevalence'] as num) * 100).toStringAsFixed(0)}% prevalence, ~${typeData['typical_count_when_present']} per view',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(
    List<dynamic>? samplesLeft,
    List<dynamic>? samplesRight,
  ) {
    // Collect up to 3 images from each side
    final leftImages =
        samplesLeft
            ?.take(3)
            .map((sample) => sample['overlay_sidewalk_png_b64'] as String?)
            .whereType<String>()
            .toList() ??
        [];
    final rightImages =
        samplesRight
            ?.take(3)
            .map((sample) => sample['overlay_sidewalk_png_b64'] as String?)
            .whereType<String>()
            .toList() ??
        [];

    // Interleave images: left1, right1, left2, right2, left3, right3
    final allImages = <Map<String, dynamic>>[];
    final maxLength = leftImages.length > rightImages.length
        ? leftImages.length
        : rightImages.length;

    for (int i = 0; i < maxLength; i++) {
      if (i < leftImages.length) {
        allImages.add({'image': leftImages[i], 'side': 'Left', 'index': i + 1});
      }
      if (i < rightImages.length) {
        allImages.add({
          'image': rightImages[i],
          'side': 'Right',
          'index': i + 1,
        });
      }
    }

    if (allImages.isEmpty) {
      return const Text('No images available');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        final item = allImages[index];
        return _buildGridImage(
          item['image'] as String,
          '${item['side']} #${item['index']}',
        );
      },
    );
  }

  Widget _buildGridImage(String base64Image, String label) {
    return GestureDetector(
      onTap: () {
        // Show full-size image in dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(label),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: Image.memory(
                      base64.decode(base64Image),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Image.memory(
                base64.decode(base64Image),
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidthRangeVisual(num minWidth, num maxWidth, num? medianWidth) {
    final min = minWidth.toDouble();
    final max = maxWidth.toDouble();
    final median = medianWidth?.toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Width Range:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Min: ${min.toStringAsFixed(2)}m',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
        Expanded(
          flex: 1,
          child: CustomPaint(
            size: const Size(double.infinity, 60),
            painter: _RangeBarPainter(
              minValue: min,
              maxValue: max,
              medianValue: median,
            ),
          ),
        ),
        //SizedBox(width: 2),
        Text(
          'Max: ${max.toStringAsFixed(2)}m',
          style: const TextStyle(fontSize: 12),
        ),
        Spacer(),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildImageSection(String? title, String? base64Image) {
    if (base64Image == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64.decode(base64Image),
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _getAccessibilityColor(String? rating) {
    if (rating == null) return null;

    switch (rating.toUpperCase()) {
      case 'EXCELLENT':
        return Colors.green.shade50;
      case 'GOOD':
        return Colors.lightGreen.shade50;
      case 'ADEQUATE':
        return Colors.yellow.shade50;
      case 'POOR':
        return Colors.orange.shade50;
      case 'INADEQUATE':
        return Colors.red.shade50;
      default:
        return null;
    }
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      // Validate inputs
      if (!_useCoordinates && _addressController.text.isEmpty) {
        throw Exception('Please enter an address');
      }
      if (_useCoordinates &&
          (_latController.text.isEmpty || _lonController.text.isEmpty)) {
        throw Exception('Please enter both latitude and longitude');
      }

      // Prepare request body
      final body = <String, dynamic>{
        'refine': _refine,
        'force_fallback': _forceFallback,
        'return_mask': _returnMask,
        'depth': _depthBackend,
        'min_clear': double.parse(_minClearController.text),
      };

      // Add optional parameters
      if (_zoeVariant != null && _zoeVariant!.isNotEmpty) {
        body['zoe_variant'] = _zoeVariant;
      }
      if (_fallbackScaleController.text.isNotEmpty) {
        body['fallback_scale'] = double.parse(_fallbackScaleController.text);
      }

      // Add location data
      if (_useCoordinates) {
        body.addAll({
          'lat': double.parse(_latController.text),
          'lon': double.parse(_lonController.text),
        });

        // Heading, pitch, and fov only for single view
        if (!_multiView) {
          body['heading'] = int.parse(_headingController.text);
          body['pitch'] = int.parse(_pitchController.text);
          body['fov'] = int.parse(_fovController.text);
        }
      } else {
        body['address'] = _addressController.text;

        // For single view with address, still send heading, pitch, and fov
        if (!_multiView) {
          body['heading'] = int.parse(_headingController.text);
          body['pitch'] = int.parse(_pitchController.text);
          body['fov'] = int.parse(_fovController.text);
        }
      }

      // Determine endpoint
      final endpoint = _multiView ? '/analyse/multi' : '/analyse/single';

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      // Handle response
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          if (_multiView) {
            _result = MultiResp.fromJson(jsonResponse);
          } else {
            _result = SingleResp.fromJson(jsonResponse);
          }
        });
      } else {
        final errorBody = response.body;
        String errorMessage;
        try {
          final errorJson = json.decode(errorBody);
          errorMessage = errorJson['detail'] ?? errorBody;
        } catch (e) {
          errorMessage = errorBody;
        }
        setState(() {
          _error = 'API Error (${response.statusCode}): $errorMessage';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _headingController.dispose();
    _pitchController.dispose();
    _fovController.dispose();
    _fallbackScaleController.dispose();
    _minClearController.dispose();
    super.dispose();
  }
}

// Custom painter for the width range visualization
class _RangeBarPainter extends CustomPainter {
  final double minValue;
  final double maxValue;
  final double? medianValue;

  _RangeBarPainter({
    required this.minValue,
    required this.maxValue,
    this.medianValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final lineY = size.height / 2;
    final startX = 10.0;
    final endX = size.width - 10;

    // Draw the horizontal line (range)
    paint.color = Colors.grey[400]!;
    paint.strokeWidth = 3;
    canvas.drawLine(Offset(startX, lineY), Offset(endX, lineY), paint);

    // Draw filled bar in the middle (represents the range more prominently)
    final barHeight = 12.0;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, lineY - barHeight / 2, endX - startX, barHeight),
      const Radius.circular(6),
    );
    paint.color = Colors.teal.withOpacity(0.3);
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(barRect, paint);

    // Draw border around bar
    paint.color = Colors.teal;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawRRect(barRect, paint);

    // Draw min circle
    paint.style = PaintingStyle.fill;
    paint.color = Colors.orange;
    canvas.drawCircle(Offset(startX, lineY), 6, paint);
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(Offset(startX, lineY), 6, paint);

    // Draw max circle
    paint.style = PaintingStyle.fill;
    paint.color = Colors.orange;
    canvas.drawCircle(Offset(endX, lineY), 6, paint);
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(Offset(endX, lineY), 6, paint);

    // Draw median marker if provided
    if (medianValue != null && maxValue > minValue) {
      final range = maxValue - minValue;
      final medianPosition =
          startX + ((medianValue! - minValue) / range) * (endX - startX);

      // Draw median line
      paint.style = PaintingStyle.fill;
      paint.color = Colors.blue[700]!;
      paint.strokeWidth = 3;
      canvas.drawLine(
        Offset(medianPosition, lineY - barHeight / 2 - 2),
        Offset(medianPosition, lineY + barHeight / 2 + 2),
        paint,
      );

      // Draw median circle
      canvas.drawCircle(Offset(medianPosition, lineY), 5, paint);
      paint.color = Colors.white;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.5;
      canvas.drawCircle(Offset(medianPosition, lineY), 5, paint);
    }
  }

  @override
  bool shouldRepaint(_RangeBarPainter oldDelegate) {
    return oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.medianValue != medianValue;
  }
}
