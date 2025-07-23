class DomainSpeedData {
  final String domain;
  final double timeMs; // 下載時間，單位毫秒

  DomainSpeedData({required this.domain, required this.timeMs});

  // 將物件轉換為 JSON 格式
  Map<String, dynamic> toJson() => {
    'domain': domain,
    'time': timeMs,
  };

  // 從 JSON 創建物件
  factory DomainSpeedData.fromJson(Map<String, dynamic> json) {
    return DomainSpeedData(
      domain: json['domain'] as String,
      timeMs: (json['time'] as num).toDouble(), // 確保轉換為 double
    );
  }

  // 方便印出和比較
  @override
  String toString() => '{"domain": "$domain", "time": $timeMs}';

}
