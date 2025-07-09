class WidthResp {
  final double width_m;
  final double margin_m;
  final String? gsv_png_b64;
  final String? mask_png_b64;
  final String? overlay_png_b64;

  WidthResp({
    required this.width_m,
    required this.margin_m,
    this.gsv_png_b64,
    this.mask_png_b64,
    this.overlay_png_b64,
  });

  bool get hasImages =>
      gsv_png_b64 != null && mask_png_b64 != null && overlay_png_b64 != null;

  factory WidthResp.fromJson(Map<String, dynamic> json) {
    return WidthResp(
      width_m: (json['width_m'] as num).toDouble(),
      margin_m: (json['margin_m'] as num).toDouble(),
      gsv_png_b64: json['gsv_png_b64'],
      mask_png_b64: json['mask_png_b64'],
      overlay_png_b64: json['overlay_png_b64'],
    );
  }
}