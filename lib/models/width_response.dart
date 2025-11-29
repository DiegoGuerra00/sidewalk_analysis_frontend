class SingleResp {
  final double width_m;
  final double margin_m;
  final List<ClearanceItem> clearances;
  final String? gsv_png_b64;
  final String? overlay_sidewalk_png_b64;
  final String? overlay_obstacle_png_b64;
  final Map<String, dynamic>? accessibility;

  SingleResp({
    required this.width_m,
    required this.margin_m,
    required this.clearances,
    this.gsv_png_b64,
    this.overlay_sidewalk_png_b64,
    this.overlay_obstacle_png_b64,
    this.accessibility,
  });

  bool get hasImages => gsv_png_b64 != null && 
      overlay_sidewalk_png_b64 != null && 
      overlay_obstacle_png_b64 != null;

  factory SingleResp.fromJson(Map<String, dynamic> json) {
    return SingleResp(
      width_m: (json['width_m'] as num).toDouble(),
      margin_m: (json['margin_m'] as num).toDouble(),
      clearances: (json['clearances'] as List<dynamic>)
          .map((item) => ClearanceItem.fromJson(item))
          .toList(),
      gsv_png_b64: json['gsv_png_b64'],
      overlay_sidewalk_png_b64: json['overlay_sidewalk_png_b64'],
      overlay_obstacle_png_b64: json['overlay_obstacle_png_b64'],
      accessibility: json['accessibility'],
    );
  }
}

class ClearanceItem {
  final String label;
  final double? L_m;
  final double? R_m;
  final double? total_m;
  final double? obs_width;

  ClearanceItem({
    required this.label,
    this.L_m,
    this.R_m,
    this.total_m,
    this.obs_width,
  });

  factory ClearanceItem.fromJson(Map<String, dynamic> json) {
    return ClearanceItem(
      label: json['label'],
      L_m: json['L_m'] != null ? (json['L_m'] as num).toDouble() : null,
      R_m: json['R_m'] != null ? (json['R_m'] as num).toDouble() : null,
      total_m: json['total_m'] != null ? (json['total_m'] as num).toDouble() : null,
      obs_width: json['obs_width'] != null ? (json['obs_width'] as num).toDouble() : null,
    );
  }
}

class MultiResp {
  final Map<String, dynamic>? multi_metadata;
  final Map<String, MultiSideSummary>? per_side;
  final Map<String, dynamic>? all_views;
  final List<dynamic>? per_heading;
  final List<dynamic>? samples_left;
  final List<dynamic>? samples_right;

  MultiResp({
    this.multi_metadata,
    this.per_side,
    this.all_views,
    this.per_heading,
    this.samples_left,
    this.samples_right,
  });

  factory MultiResp.fromJson(Map<String, dynamic> json) {
    return MultiResp(
      multi_metadata: json['multi_metadata'],
      per_side: json['per_side'] != null ? 
        Map<String, MultiSideSummary>.from(json['per_side'].map(
          (key, value) => MapEntry(key, MultiSideSummary.fromJson(value))
        )) : null,
      all_views: json['all_views'],
      per_heading: json['per_heading'],
      samples_left: json['samples_left'],
      samples_right: json['samples_right'],
    );
  }
}

class MultiSideSummary {
  final Map<String, dynamic>? median_width;
  final Map<String, dynamic>? width_range_m;
  final MultiSideCorridor? corridor;
  final MultiSideObstacles? obstacles;

  MultiSideSummary({
    this.median_width,
    this.width_range_m,
    this.corridor,
    this.obstacles,
  });

  factory MultiSideSummary.fromJson(Map<String, dynamic> json) {
    return MultiSideSummary(
      median_width: json['median_width'],
      width_range_m: json['width_range_m'],
      corridor: json['corridor'] != null ? 
        MultiSideCorridor.fromJson(json['corridor']) : null,
      obstacles: json['obstacles'] != null ?
        MultiSideObstacles.fromJson(json['obstacles']) : null,
    );
  }
}

class MultiSideCorridor {
  final double? median_m;
  final double? meets_ratio;
  final String? rating;

  MultiSideCorridor({
    this.median_m,
    this.meets_ratio,
    this.rating,
  });

  factory MultiSideCorridor.fromJson(Map<String, dynamic> json) {
    return MultiSideCorridor(
      median_m: json['median_m'] != null ? (json['median_m'] as num).toDouble() : null,
      meets_ratio: json['meets_ratio'] != null ? (json['meets_ratio'] as num).toDouble() : null,
      rating: json['rating'],
    );
  }
}

class MultiSideObstacles {
  final int? typical_obstacles_per_view;
  final Map<String, dynamic>? types;

  MultiSideObstacles({
    this.typical_obstacles_per_view,
    this.types,
  });

  factory MultiSideObstacles.fromJson(Map<String, dynamic> json) {
    return MultiSideObstacles(
      typical_obstacles_per_view: json['typical_obstacles_per_view'],
      types: json['types'],
    );
  }
}