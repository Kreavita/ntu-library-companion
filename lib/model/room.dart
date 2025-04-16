import 'package:ntu_library_companion/util.dart';

/// A Room has a location in the library and is a rentable unit
class Room {
  final String rid;
  final String cateId;
  final String name;
  final String type;
  final String description;
  final String floor;
  final String attachmentId;

  Room({
    required this.rid,
    required this.cateId,
    required this.name,
    required this.type,
    required this.description,
    required this.floor,
    required this.attachmentId,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    String aid = (json["resourceAttachs"] as List?)?.firstOrNull?["aid"] ?? "";
    return Room(
      rid: json["rid"],
      cateId: json["cateId"],
      name: cleanHtml(json["name"] ?? ""),
      type: json["type"] ?? "",
      description: cleanHtml(json["description"] ?? ""),
      floor: cleanHtml(json["resourceLocation"]?["name"] ?? ""),
      attachmentId: aid,
    );
  }
}
