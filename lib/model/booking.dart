import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/model/account.dart';
import 'package:ntu_library_companion/model/room.dart';
import 'package:ntu_library_companion/model/student.dart';

final DateFormat _df = DateFormat('yyyy/MM/dd HH:mm:ss');

class BookingStatus {
  final String message;
  final IconData icon;
  final Color? color;

  BookingStatus(this.message, this.icon, this.color);
}

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

  BookingStatus friendlyStatus(BuildContext context) {
    IconData icon = Icons.question_mark;
    Color? color;
    String message = "Unknown";
    switch (status) {
      case "Z":
        message = "Absent timeout";
        icon = Icons.warning_amber;
        color = Theme.of(context).colorScheme.error;
        break;
      case "O":
        message = "Check-in timeout"; // Report timeout
        icon = Icons.lock_clock_outlined;
        color = Theme.of(context).colorScheme.error;
        break;
      case "F":
        message = "Finished";
        icon = Icons.task_alt_rounded;
        break;
      case "T":
        message = "Aborted";
        icon = Icons.event_busy_outlined;
        color = Colors.pinkAccent;
        break;
      case "Y":
        message = "Reserved";
        icon = Icons.event_available_outlined;
        color = Theme.of(context).colorScheme.primary;
        break;
      case "L":
        message = "Leave temporarily";
        icon = Icons.exit_to_app;
        color = Colors.purpleAccent;
        break;
      case "U":
        message = "In use";
        icon = Icons.play_circle;
        color = Colors.greenAccent;
        break;
      case "C":
        message = "Cancelled";
        icon = Icons.free_cancellation_outlined;
        color = Colors.grey;
        break;
      case "I":
        message = "Check-in required!"; // Reporting
        icon = Icons.nfc;
        color = Colors.orange;
        break;
      default:
        break;
    }
    return BookingStatus(message, icon, color);
  }

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
      type: json["mainResourceType"],
      name: json["mainResourceName"],
      description: "No Description provided",
      floor: "No Floor provided",
      attachmentId: "",
    );

    // Booking Participants Data is also the same for all requests
    final List<Student> bp =
        json['bookingParticipants']?.map<Student>((p) {
          return Student(
            uuid: p["participantId"],
            account: p["participantAccount"],
            name: p["participantName"],
          );
        }).toList() ??
        [];

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
