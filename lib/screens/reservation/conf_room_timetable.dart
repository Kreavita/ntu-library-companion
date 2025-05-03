import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/conference_room.dart';
import 'package:ntu_library_companion/util.dart';
import 'package:ntu_library_companion/widgets/centered_content.dart';
import 'package:ntu_library_companion/widgets/info_row.dart';

class ConfRoomTimetable extends StatelessWidget {
  final DateTime date;
  final List<TimeOfDay> ttEntry;
  final Future<Map<ConferenceRoom, List<Booking>>> bookings;

  const ConfRoomTimetable({
    super.key,
    required this.date,
    required this.ttEntry,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Timetable")),
      body: CenterContent(
        child: FutureBuilder(
          future: bookings,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              snapshot.data?.removeWhere((_, bookings) {
                bookings.removeWhere(
                  (booking) =>
                      booking.bookingEndDate.day != date.day ||
                      booking.bookingEndDate.month != date.month ||
                      booking.bookingEndDate.year != date.year,
                );
                return bookings.isEmpty;
              });
              return SingleChildScrollView(
                child: Column(
                  spacing: 8,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "Conference Rooms on ${DateFormat("EEE,").format(date)} ${DateFormat("MMM d").format(date)}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InfoRow(
                      icon: Icons.info_outline,
                      child: Text(
                        "The following table shows free, used and reserved timeslots of all Conference Rooms on ${DateFormat("EEEE,").format(date)} ${DateFormat("MMM d y").format(date)}.\nThe red line marks the current time.",
                      ),
                    ),
                    (snapshot.data?.isEmpty ?? true)
                        ? Center(
                          child: InfoRow(
                            icon: Icons.no_sim_outlined,
                            child: Text(
                              "No Booking Information Available",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        )
                        : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildTimetable(context, snapshot.data!),
                          ),
                        ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              // Error occurred, display error message
              return Text('Error: ${snapshot.error}');
            } else {
              // Data is not available yet, display a loading indicator
              return Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  CircularProgressIndicator(),
                  Flexible(
                    child: Text(
                      "Retrieving Conference Room Reservations...",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildTimetable(
    BuildContext context,
    Map<ConferenceRoom, List<Booking>> data,
  ) {
    int startIndex = ttEntry[0].hour * 2 + ttEntry[0].minute;
    int endIndex = ttEntry[1].hour * 2 + ttEntry[1].minute;
    DateTime now = DateTime.now(); // for the time index
    return Column(
      children: [
        Row(
          spacing: 0,
          children: List.generate(data.length + 1, (index) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 1.0, // Set the width of the border
                  ),
                ),
              ),
              width: 51,
              height: 32,
              child: Text(
                textAlign: TextAlign.center,
                index == 0 ? "Times" : data.keys.elementAt(index - 1).name,
              ),
            );
          }),
        ),
        Stack(
          children: [
            Row(
              spacing: 1,
              children: [
                // Legend column
                SizedBox(
                  width: 50,
                  child: Column(
                    spacing: 0,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate((endIndex - startIndex) ~/ 2, (
                      index,
                    ) {
                      index = startIndex + index * 2;
                      int hour = index ~/ 2;
                      int minute = (index % 2) * 30;
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border:
                              index == startIndex
                                  ? null
                                  : Border(
                                    top: BorderSide(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      width: 1.0, // Set the width of the border
                                    ),
                                  ),
                        ),
                        height: 42,
                        width: double.infinity,
                        child: Text(
                          '$hour:${minute.toString().padLeft(2, '0')}',
                        ),
                      );
                    }),
                  ),
                ),
                // Rooms columns
                ...List.generate(data.keys.length, (index) {
                  return SizedBox(
                    width: 50,
                    child: Column(
                      spacing: 1,
                      children: List.generate(endIndex - startIndex, (
                        timeIndex,
                      ) {
                        timeIndex += startIndex;
                        int hour = timeIndex ~/ 2;
                        int minute = (timeIndex % 2) * 30;

                        final List<Booking> bookings =
                            data[data.keys.elementAt(index)]!;

                        final filteredBookings = bookings.where((b) {
                          DateTime ttDate = b.bookingStartDate.copyWith(
                            hour: hour,
                            minute: minute,
                            day: date.day,
                            month: date.month,
                            year: date.year,
                          );

                          return ttDate.isWithin(
                            b.bookingStartDate,
                            b.bookingEndDate,
                          );
                        });

                        final bool inThePast = date
                            .copyWith(hour: hour, minute: minute)
                            .isBefore(now.add(Duration(minutes: -30)));

                        final theme = Theme.of(context).colorScheme;

                        List<Object> appearance =
                            (inThePast)
                                ? [theme.surface, theme.onSurface, ""]
                                : [theme.primary, theme.onPrimary, "free"];

                        if (filteredBookings.any(
                          (b) => ["U", "F", "L", "Z"].contains(b.status),
                        )) {
                          appearance = [
                            theme.primaryContainer.withAlpha(100),
                            theme.onPrimaryContainer,
                            "used",
                          ];
                        } else if (filteredBookings.any(
                          (b) => ["Y", "I"].contains(b.status),
                        )) {
                          appearance = [
                            theme.primaryContainer,
                            theme.onPrimaryContainer,
                            "rsvd",
                          ];
                        }

                        if (inThePast) {
                          appearance[0] = (appearance[0] as Color).withAlpha(
                            ((appearance[0] as Color).a * 100).round(),
                          );
                          appearance[1] = (appearance[1] as Color).withAlpha(
                            ((appearance[1] as Color).a * 100).round(),
                          );
                        }

                        return Container(
                          height: 20,
                          width: 50,
                          color: appearance[0] as Color,
                          child: Text(
                            appearance[2] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: appearance[1] as Color),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
            Positioned(
              top:
                  (now.hour * 60 + now.minute - startIndex * 30) *
                  (2 / 3 + 1 / 30),
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                width: double.infinity,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
