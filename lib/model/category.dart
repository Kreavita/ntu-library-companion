import 'package:ntu_library_companion/model/branch.dart';
import 'package:ntu_library_companion/util.dart';

/// A Category is a Rentable Type of Room or Service that the library offers
class Category {
  final String catId;
  final String type;
  final String name;
  final String engName;
  final String description;
  final String attachmentId;
  final Branch branch;
  final String bookingEngDesc;
  final Map<String, dynamic> bookingPolicy;
  final Map<String, dynamic> openPolicy;

  Category({
    required this.catId,
    required this.type,
    required this.name,
    required this.engName,
    required this.description,
    required this.attachmentId,
    required this.branch,
    required this.bookingEngDesc,
    required this.bookingPolicy,
    required this.openPolicy,
  });

  factory Category.fromJson(Map<String, dynamic> jsonObj) {
    List<dynamic> attachments = jsonObj["resourceCateAttachs"];
    return Category(
      catId: jsonObj['cateId'] as String,
      type: jsonObj['type'],
      name: cleanHtml(jsonObj['name'] as String),
      engName: cleanHtml(jsonObj['engName'] as String),
      description: cleanHtml(jsonObj['description'] ?? "No Description"),
      attachmentId: attachments.firstOrNull?["aid"] ?? "",
      branch: Branch.fromJson(jsonObj["branch"]),
      bookingEngDesc: cleanHtml(
        jsonObj['bookingEngDesc'] ?? "No Booking information",
      ),
      bookingPolicy:
          jsonObj["councilPolicy"]?["resourceBookingPolicy"]?["policyContents"] ??
          {} as Map<String, dynamic>,
      openPolicy:
          jsonObj["openingPolicy"]?["policyContents"] ??
          {} as Map<String, dynamic>,
    );
  }
}
