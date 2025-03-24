final Map<String, String> _zhToEn = {
  "總圖": "Main Library",
  "總館": "Main Library",
  "總圖書館": "Main Library",
  "社圖": "Social Sciences Library",
  "社科院圖書館": "Social Sciences Library",
  "醫學院圖書館": "Medical Library",
  "法學院圖書館": "Law Library",
  "國立臺灣大學圖書館": "National Taiwan University Library",
};

/// A Branch is one division of the NTU library system.
class Branch {
  final String bid;
  final String code;
  final String name;

  get enName => _zhToEn[name] ?? "Unknown Location";

  Branch({required this.bid, required this.code, required this.name});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      bid: json["bid"] ?? "",
      code: json["code"] ?? "",
      name: json["name"] ?? "",
    );
  }
}
