import 'package:ntu_library_companion/model/room.dart';

class ConferenceRoom extends Room {
  final int capacityLowerLimit;
  final int capacityUpperLimit;

  ConferenceRoom({
    required super.rid,
    required super.cateId,
    required super.name,
    required super.description,
    required super.floor,
    required super.attachmentId,
    required this.capacityLowerLimit,
    required this.capacityUpperLimit,
  });

  factory ConferenceRoom.fromJson(Map<String, dynamic> json) {
    String aid = "";

    List<dynamic> resourceAttachs = json['resourceAttachs'];
    if (resourceAttachs.isNotEmpty) {
      aid = resourceAttachs[0]['aid'] as String;
    }

    return ConferenceRoom(
      rid: json['rid'],
      cateId: json['cateId'],
      name: json['name'],
      description: json['description'],
      floor: "Unknown",
      attachmentId: aid, // Provide a default value if null
      capacityLowerLimit: json['capacityLowerLimit'] as int,
      capacityUpperLimit: json['capacityUpperLimit'] as int,
    );
  }
}
