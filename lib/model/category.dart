import 'package:ntu_library_companion/model/branch.dart';
import 'package:ntu_library_companion/util.dart';

/// A Category is a Rentable Type of Room or Service that the library offers
class Category {
  final String catId;
  final String name;
  final String description;
  final String attachmentId;
  final Branch branch;
  final int available;
  final int capacity;
  final String bookingEngDesc;
  final Map<String, dynamic> bookingPolicy;
  final Map<String, dynamic> openPolicy;

  Category({
    required this.catId,
    required this.name,
    required this.description,
    required this.attachmentId,
    required this.branch,
    required this.available,
    required this.capacity,
    required this.bookingEngDesc,
    required this.bookingPolicy,
    required this.openPolicy,
  });

  factory Category.fromJson(
    Map<String, dynamic> jsonObj,
    int avail,
    int count,
  ) {
    List<dynamic> attachments = jsonObj["resourceCateAttachs"];
    return Category(
      catId: jsonObj['cateId'] as String,
      name: cleanHtml(jsonObj['engName'] as String),
      description: cleanHtml(jsonObj['description'] ?? "No Description"),
      attachmentId: attachments.firstOrNull?["aid"] ?? "",
      branch: Branch.fromJson(jsonObj["branch"]),
      available: avail,
      capacity: count,
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
