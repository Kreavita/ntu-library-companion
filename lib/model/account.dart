import 'package:intl/intl.dart';
import 'package:ntu_library_companion/model/student.dart';

class Account extends Student {
  final String email;
  final String status;
  final String titleId;
  final String titleName;
  final DateTime validEndDate;

  Account({
    required super.uuid,
    required super.account,
    required super.name,
    required this.email, // Comma separated
    required this.status, // Active "Y" / Inactive "N"
    required this.titleId, // Study Program ID
    required this.titleName, // Study Program (Undergrad, Grad, ...)
    required this.validEndDate, // expiration date YYYY/MM/DD HH:MM:SS
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      uuid: json["uuid"],
      account: json["account"],
      email: json["email"] ?? "",
      name: json["name"],
      status: json["status"] ?? "",
      titleId: json["tilteId"] ?? "",
      titleName: json["titleName"] ?? "",
      validEndDate: DateFormat(
        'yyyy/MM/dd HH:mm:ss',
      ).parse(json["validEndDate"]),
    );
  }
}
