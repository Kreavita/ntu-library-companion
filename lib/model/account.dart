import 'package:intl/intl.dart';
import 'package:ntu_library_companion/model/student.dart';

class Account extends Student {
  // Personal Info
  final String phone; // Only Member
  final String email;
  final DateTime birthDay;
  final String titleId;
  final String titleName;

  // Account Metadata
  final String cardNo; // Only Member
  final String status; // Only Member
  final String emailVerified; // Only Member
  final DateTime createDate; // Only Member
  final DateTime validEndDate; // Only Account

  Account({
    required super.uuid,
    required super.account,
    required super.name,
    required this.phone,
    required this.email, // Comma separated
    required this.birthDay,
    required this.titleId, // Study Program ID
    required this.titleName, // Study Program (Undergrad, Grad, ...)
    required this.cardNo,
    required this.status, // Active "Y" / Inactive "N"
    required this.emailVerified,
    required this.createDate, // account creation date YYYY/MM/DD HH:MM:SS
    required this.validEndDate, // expiration date YYYY/MM/DD HH:MM:SS
  });

  factory Account.fromJson({
    Map<String, dynamic>? accountData,
    Map<String, dynamic>? profileData,
  }) {
    DateFormat df = DateFormat('yyyy/MM/dd HH:mm:ss');
    String defaultDate = df.format(DateTime(1970));

    Map<String, dynamic>? json = accountData;
    if (profileData != null) {
      json = profileData["memberAccount"];
    }

    List<String> phoneData = [];
    if ((json!["contactHomeTel"]?.trim() ?? '') != '') {
      phoneData.add(json["contactHomeTel"].trim());
    }
    if ((json["contactMobileTel"]?.trim() ?? '') != '') {
      phoneData.add(json["contactMobileTel"].trim());
    }

    return Account(
      uuid: json["uuid"],
      account: json["account"],
      email: json["email"] ?? "",
      name: json["name"],
      status: json["status"] ?? "Y",
      titleId: json["titleId"] ?? "Unknown",
      titleName: json["titleName"] ?? "Unknown",
      validEndDate: df.parse(json["validEndDate"] ?? defaultDate),
      birthDay: df.parse(json["birthday"] ?? defaultDate),
      phone: phoneData.join(","),
      emailVerified: json["cardNo"] ?? "N",
      createDate: df.parse(json["birth"] ?? defaultDate),
      cardNo: json["cardNo"] ?? "Unknown",
    );
  }
}
