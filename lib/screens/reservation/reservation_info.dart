import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/model/booking.dart';

class ReservationInfo extends StatefulWidget {
  final Booking booking;
  const ReservationInfo({super.key, required this.booking});

  @override
  State<ReservationInfo> createState() => _ReservationInfoState();
}

class _ReservationInfoState extends State<ReservationInfo> {
  @override
  Widget build(BuildContext context) {
    DateFormat df = DateFormat("d/M/y HH:mm");
    String start = df.format(widget.booking.bookingStartDate);
    String end = DateFormat("HH:mm").format(widget.booking.bookingEndDate);
    String checkIn = df.format(
      widget.booking.bookingStartDate.add(Duration(minutes: 15)),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Booked: Room ${widget.booking.room.name}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.meeting_room_outlined, size: 32),
            ],
          ),
          Row(
            spacing: 5,
            children: [
              Icon(Icons.timelapse_outlined),
              Text("Timespan: "),
              Expanded(child: Text("$start - $end", textAlign: TextAlign.end)),
            ],
          ),
          Row(
            spacing: 5,
            children: [
              Icon(Icons.alarm),
              Text("Check-In before: "),
              Expanded(child: Text(checkIn, textAlign: TextAlign.end)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Participants: "),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 5.0,
              children:
                  widget.booking.bookingParticipants.map((bp) {
                    return Chip(
                      avatar: Icon(Icons.account_circle_outlined),
                      label: Text(bp.name),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
