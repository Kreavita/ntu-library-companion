import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/widgets/centered_content.dart';
import 'package:provider/provider.dart';

class BookingHistory extends StatefulWidget {
  const BookingHistory({super.key});

  @override
  State<BookingHistory> createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  final LibraryService _library = LibraryService();
  AuthService? _auth;
  SettingsProvider? _settings;

  bool _fetching = false;
  bool _complete = false;
  List<Booking> _history = [];

  @override
  Widget build(BuildContext context) {
    _settings ??= Provider.of<SettingsProvider>(context);
    _auth ??= AuthService(settings: _settings!);

    if (!_fetching) fetchHistory();

    return Scaffold(
      appBar: AppBar(title: Text("Booking History")),
      body: CenterContent(
        child:
            (_complete)
                ? ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final b = _history[index];
                    final from = DateFormat(
                      'MMM d, HH:mm',
                    ).format(b.bookingStartDate);
                    final to = DateFormat('HH:mm').format(b.bookingEndDate);

                    return Column(
                      children: [
                        ListTile(
                          trailing: interpretStatus(b.status),
                          title: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Icon(Icons.sensor_door_outlined),
                                ),
                                Text("Room '${b.room.name}'"),
                              ],
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$from - $to",
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Wrap(
                                    spacing: 5.0,
                                    children:
                                        b.bookingParticipants
                                            .map(
                                              (s) => Chip(
                                                avatar: Icon(
                                                  Icons.account_circle_outlined,
                                                ),
                                                label: Text(s.name),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          //trailing: Column(children: [Text("From: "), Text("To: ")]),
                        ),
                        Divider(),
                      ],
                    );
                  },
                )
                : Center(child: CircularProgressIndicator()),
      ),
    );
  }

  fetchHistory() async {
    if (_fetching) return;
    _fetching = true;

    final authToken = await _auth!.getToken();

    if (authToken == null) {
      _fetching = false;
      return;
    }

    _history = await _library.getBookings(authToken, includePast: true);

    if (mounted) {
      setState(() {
        _complete = true;
      });
    }
  }

  Widget interpretStatus(String status) {
    Icon icon = Icon(
      Icons.question_mark,
      color: Theme.of(context).colorScheme.error,
    );
    String message = "Unknown";
    switch (status) {
      case "Z":
        message = "Absent timeout";
        icon = Icon(
          Icons.warning_amber,
          color: Theme.of(context).colorScheme.error,
        );
        break;
      case "O":
        message = "Report timeout";
        icon = Icon(
          Icons.warning_amber,
          color: Theme.of(context).colorScheme.error,
        );
        break;
      case "F":
        message = "Finished";
        icon = Icon(Icons.event_available_outlined);
        break;
      case "T":
        message = "Aborted";
        icon = Icon(Icons.event_busy_outlined, color: Colors.pinkAccent);
        break;
      case "Y":
        message = "Reserved";
        icon = Icon(Icons.check, color: Colors.green);
        break;
      case "L":
        message = "Leave temporarily";
        icon = Icon(Icons.exit_to_app, color: Colors.purpleAccent);
        break;
      case "U":
        message = "In use";
        icon = Icon(
          Icons.play_circle,
          color: Theme.of(context).colorScheme.primary,
        );
        break;
      case "C":
        message = "Cancelled";
        icon = Icon(Icons.free_cancellation_outlined, color: Colors.cyan);
        break;
      case "I":
        message = "Reporting";
        icon = Icon(Icons.refresh);
        break;
      default:
        break;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: [icon, Text(message)],
    );
  }
}
