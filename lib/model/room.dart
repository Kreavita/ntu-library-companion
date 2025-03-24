import 'package:ntu_library_companion/util.dart';

/// A Cate is a Type of Room or Service that the library offers
class Room {
  final String rid;
  final String cateId;
  final String name;
  final String description;
  final String floor;
  final String attachmentId;

  Room({
    required this.rid,
    required this.cateId,
    required this.name,
    required this.description,
    required this.floor,
    required this.attachmentId,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    String aid = "";
    if ((json["resourceAttachs"] as List).isNotEmpty) {
      aid = json["resourceAttachs"]?.first["aid"];
    }
    return Room(
      rid: json["rid"],
      cateId: json["cateId"],
      name: cleanHtml(json["name"] ?? ""),
      description: cleanHtml(json["description"] ?? ""),
      floor: cleanHtml(json["resourceLocation"]?["name"] ?? ""),
      attachmentId: aid,
    );
  }
}
