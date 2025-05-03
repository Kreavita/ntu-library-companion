import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/screens/profile/booking_history.dart';
import 'package:ntu_library_companion/widgets/info_row.dart';

class ReservationBanner extends StatelessWidget {
  final void Function() onRefresh;
  final void Function()? onAction;
  final Booking? booking;
  final bool loggedIn;
  final bool finishedRequest;

  const ReservationBanner({
    super.key,
    required this.onRefresh,
    this.onAction,
    required this.booking,
    required this.finishedRequest,
    required this.loggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onLongPress: loggedIn ? onRefresh : null,
          onTap:
              loggedIn
                  ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => BookingHistory()),
                  )
                  : null,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                (booking != null)
                    ? _buildBannerContent(context, booking!)
                    : ((finishedRequest)
                        ? Center(
                          child: InfoRow(
                            icon:
                                loggedIn
                                    ? Icons.event_busy_outlined
                                    : Icons.no_accounts,
                            child: Text(
                              loggedIn
                                  ? "No active reservation"
                                  : "Login required to view reservations",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : LinearProgressIndicator()),

                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 8,
                  children: [
                    Flexible(
                      child: Text(
                        "Long press to reload – Tap for booking history",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (loggedIn && onAction != null)
                      FilledButton.icon(
                        onPressed: onAction,
                        icon: Icon(
                          (booking?.status == "Y")
                              ? Icons.event_busy_outlined
                              : Icons.exit_to_app,
                        ),
                        label: Text(
                          (booking?.status == "Y") ? "Cancel" : "Return Room",
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerContent(BuildContext context, Booking booking) {
    DateFormat df = DateFormat("d/M/y HH:mm");
    String start = df.format(booking.bookingStartDate);
    String end = DateFormat("HH:mm").format(booking.bookingEndDate);
    String checkIn = df.format(
      booking.bookingStartDate.add(Duration(minutes: 15)),
    );

    BookingStatus bStatus = booking.friendlyStatus(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //Icon(Icons.meeting_room_outlined, size: 32),
              Flexible(
                child: Text(
                  "Booked: ${SettingsProvider.type2engName[booking.room.type] ?? "Room"} ${booking.room.name}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              Row(
                spacing: 4.0,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(bStatus.icon, color: bStatus.color),
                  Text(
                    bStatus.message,
                    style: TextStyle(
                      color: bStatus.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
            child: Text(
              booking.bookingParticipants.isEmpty
                  ? "No participants"
                  : "Participants: ",
            ),
          ),
          if (booking.bookingParticipants.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 5.0,
                children:
                    booking.bookingParticipants.map((bp) {
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
