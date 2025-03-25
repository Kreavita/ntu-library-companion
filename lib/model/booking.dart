import 'package:intl/intl.dart';
import 'package:ntu_library_companion/model/account.dart';
import 'package:ntu_library_companion/model/room.dart';
import 'package:ntu_library_companion/model/student.dart';

final DateFormat _df = DateFormat('yyyy/MM/dd HH:mm:ss');

class Booking {
  final String bid; // booking id
  final String bookingCode;

  final Account host;
  final DateTime bookingStartDate;
  final DateTime bookingEndDate;
  final List<Student> bookingParticipants;
  final Room room; // Room ID

  // Metadata for the booking request
  final DateTime createDate;
  final DateTime lastModifyDate;

  final String status;

  Booking({
    required this.bid,
    required this.bookingCode,
    required this.host,
    required this.bookingStartDate,
    required this.bookingEndDate,
    required this.bookingParticipants,
    required this.room,
    required this.createDate,
    required this.lastModifyDate,
    required this.status,
  });

  factory Booking.fromJson({
    Map<String, dynamic>? bookingJson, // from getBooking(bid)
    Map<String, dynamic>? bookingsJson, // from getBookings()
    Map<String, dynamic>? postBookingJson, // from postBooking()
  }) {
    Map<String, dynamic> json;
    Room room;
    Account host;
    List<Student> bp = [];

    if (bookingJson != null) {
      json = bookingJson;
      room = Room(
        rid: json['mainResourceId'],
        cateId: json['mainResourceCateId'],
        name: json['mainResourceName'],
        description: json['mainResourceCateId'],
        floor: json['mainResourceCateId'],
        attachmentId: json['mainResourceCateId'],
      );
      host = Account.fromJson(accountData: json['applicant']);
    } else if (bookingsJson != null) {
      json = bookingsJson;
      room = Room(
        rid: json['mainResourceId'],
        attachmentId: "",
        name: json["mainResourceName"],
        cateId: json["mainResourceCateId"],
        description: "",
        floor: "",
      );
      host = Account(
        account: json['hostAccount'],
        name: json['hostName'],
        email: '',
        status: '',
        uuid: json['hostId'],
        titleId: json['hostTitleId'],
        titleName: json['hostTitleName'],
        validEndDate: DateTime.now(),
        phone: '',
        birthDay: DateTime.now(),
        cardNo: '',
        emailVerified: '',
        createDate: DateTime.now(),
      );
      bp =
          json['bookingParticipants'].map<Student>((p) {
            return Student(
              uuid: p["pid"],
              account: p["participantAccount"],
              name: p["participantName"],
            );
          }).toList();
    } else {
      json = postBookingJson!;
      room = Room(
        rid: json['rid'],
        attachmentId: "",
        name: "",
        cateId: "",
        description: "",
        floor: "",
      );
      host = Account.fromJson(accountData: json['host']);
    }

    return Booking(
      bid: json['bid'],
      bookingCode: json['bookingCode'],
      host: host,
      bookingStartDate: _df.parse(json['bookingStartDate']),
      bookingEndDate: _df.parse(json['bookingEndDate']),
      bookingParticipants: bp,
      room: room,
      createDate: _df.parse(json['createDate']),
      lastModifyDate: _df.parse(json['lastModifyDate']),
      status: json["status"],
    );
  }
}
