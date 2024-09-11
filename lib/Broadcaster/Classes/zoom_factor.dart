class ZoomFactor {
  final int maxZoom;
  final int minZoom;

  ZoomFactor({
    required this.maxZoom,
    required this.minZoom,
  });

  factory ZoomFactor.fromMap(Map<String, dynamic> map) {
    return ZoomFactor(
      maxZoom: map['max'],
      minZoom: map['min'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'max': maxZoom,
      'min': minZoom,
    };
  }
}
