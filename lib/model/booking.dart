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
    Account host;

    if (bookingJson != null) {
      json = bookingJson;
      host = Account.fromJson(accountData: json['applicant']);
    } else {
      json = bookingsJson ?? postBookingJson!;
      host = Account(
        uuid: json['hostId'],
        account: json['hostAccount'] ?? "Not Provided",
        name: json['hostName'],
        phone: '',
        email: '',
        birthDay: DateTime.now(),
        titleId: json['hostTitleId'],
        titleName: json['hostTitleName'],
        cardNo: 'Not Provided',
        status: 'Y',
        emailVerified: 'N',
        createDate: DateTime.now(),
        validEndDate: DateTime.now(),
      );
    }
    // Room Info is the same for all the booking request types
    final Room room = Room(
      rid: json['mainResourceId'],
      cateId: json["mainResourceCateId"],
      name: json["mainResourceName"],
      description: "No Description provided",
      floor: "No Floor provided",
      attachmentId: "",
    );

    // Booking Participants Data is also the same for all requests
    final List<Student> bp =
        json['bookingParticipants'].map<Student>((p) {
          return Student(
            uuid: p["participantId"],
            account: p["participantAccount"],
            name: p["participantName"],
          );
        }).toList();

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
