import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/account.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/category.dart';
import 'package:ntu_library_companion/model/conference_room.dart';
import 'package:ntu_library_companion/model/room.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/model/student.dart';
import 'package:ntu_library_companion/screens/reservation/conf_room_timetable.dart';
import 'package:ntu_library_companion/screens/reservation/participant_picker.dart';
import 'package:ntu_library_companion/screens/reservation/room_picker.dart';
import 'package:ntu_library_companion/util.dart';
import 'package:ntu_library_companion/widgets/info_row.dart';
import 'package:provider/provider.dart';

class ReservationForm extends StatefulWidget {
  final Category cate;
  final TimeTable timetable;
  final double maxHours;
  final double minHours;
  final int roundMin;

  const ReservationForm({
    super.key,
    required this.cate,
    required this.timetable,
    required this.maxHours,
    required this.roundMin,
    required this.minHours,
  });

  @override
  State<ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final _formKey = GlobalKey<FormState>();
  final LibraryService _library = LibraryService();
  late final SettingsProvider _settings = Provider.of<SettingsProvider>(
    context,
  );
  late final AuthService _auth = AuthService(settings: _settings);
  String? _authToken;

  List<ConferenceRoom> _conferenceRooms = [];
  Map<String, Student>? _contacts;

  final Set<String> _participants = <String>{};
  DateTime _date = DateTime.now();
  Room? _selectedRoom;

  var _minParticipants = 0;
  var _maxParticipants = 0;

  late TimeOfDay _start = TimeOfDay.fromDateTime(
    _date,
  ).roundDown(min: widget.roundMin);
  late TimeOfDay _end = _start.add(Duration(hours: 2));

  bool _submitting = false;

  Future<Map<ConferenceRoom, List<Booking>>>? _bookings = Future(() => {});

  Future<void> _getConfRooms() async {
    if (_conferenceRooms.isNotEmpty) return;
    final token = await _auth.getToken();
    if (token == null) return;

    setState(() {
      _authToken ??= token;
    });

    _conferenceRooms = await _library.getConferenceRooms(
      _authToken!,
      widget.cate,
    );

    _updateBookings();
  }

  _updateBookings() {
    _bookings = _library.getConfRoomBookings(
      _authToken ?? "",
      _date,
      _date.add(Duration(days: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _getConfRooms();
    _contacts ??= _settings.get("contacts");

    final ttEntry =
        widget.timetable[timetableDays[_date.weekday - 1 % 7]] ?? [];
    final colors = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).viewPadding.top;

    ConferenceRoom? c =
        _conferenceRooms
            .where((element) => (element.rid == _selectedRoom?.rid))
            .firstOrNull;

    if (c != null) {
      _minParticipants = c.capacityLowerLimit - 1;
      _maxParticipants = c.capacityUpperLimit - 1;
    }

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: EdgeInsets.only(top: topPadding)),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Reservation Form",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Choose a Day:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Flexible(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.tertiaryContainer,
                                foregroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
                                textStyle: TextStyle(fontSize: 16),
                              ),
                              onPressed: () => _selectDate(context),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(Icons.edit_calendar_outlined),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      right: 2.0,
                                    ),
                                    child: Text(
                                      DateFormat("EEE,").format(_date),
                                    ),
                                  ),
                                  Text(DateFormat("MMM d").format(_date)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Set Start and End Time:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (ttEntry.length == 2)
                      InfoRow(
                        icon: Icons.info_outline,
                        child: Text(
                          "Opened from ${ttEntry[0].format(context)} "
                          "to ${ttEntry[1].format(context)}.",
                        ),
                      ),
                    if (ttEntry.length < 2)
                      InfoRow(
                        icon: Icons.event_busy_outlined,
                        child: Text("Not open on the selected date."),
                      ),
                    InfoRow(
                      icon: Icons.timelapse_outlined,
                      child: Text(
                        "Reservation duration must be between ${(widget.minHours * 60).toAutoString()} min and ${widget.maxHours.toAutoString()} hours.",
                      ),
                    ),

                    Padding(padding: const EdgeInsets.symmetric(vertical: 4.0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(16.0),
                              ),
                              border: Border.all(
                                width: 1,
                                color: colors.onSurface,
                              ),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                              ),
                              contentPadding: EdgeInsets.all(8),
                              leading: Icon(Icons.login),
                              title: Text(
                                _start.format(context),
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text("Start time", softWrap: false),
                              onTap: () => _selectStartTime(context),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(16.0),
                              ),
                              border: Border(
                                top: BorderSide(color: colors.onSurface),
                                bottom: BorderSide(color: colors.onSurface),
                                right: BorderSide(color: colors.onSurface),
                              ),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              contentPadding: EdgeInsets.all(8),
                              trailing: Icon(Icons.exit_to_app),
                              title: Text(
                                _end.format(context),
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text("End time", softWrap: false),
                              onTap: () => _selectEndTime(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        spacing: 8,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Select Room:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.cate.type == "CRM")
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ConfRoomTimetable(
                                          date: _date,
                                          ttEntry: ttEntry,
                                          bookings: _bookings!,
                                        ),
                                  ),
                                );
                              },
                              child: Text("Timetable"),
                            ),
                        ],
                      ),
                    ),
                    RoomPicker(
                      authToken: _authToken ?? "",
                      cate: widget.cate,
                      date: _date,
                      startTime: _start,
                      endTime: _end,
                      validSelection: _validateTimes(),
                      onTap: (selectedRoom) {
                        setState(() {
                          _selectedRoom = selectedRoom;
                        });
                      },
                    ),
                    if (_selectedRoom != null)
                      InfoRow(
                        icon: Icons.group_add_outlined,
                        child: Text(
                          "The selected Room requires $_minParticipants to $_maxParticipants Participants.",
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "Add your Participants:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ParticipantPicker(
                      participants: _participants,
                      contacts: _contacts ?? {},
                      onDelete: (key) {
                        if (_participants.remove(key)) setState(() {});
                      },
                      onAdd: (key) {
                        if (_participants.add(key)) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              ),
              child: Icon(Icons.arrow_back, size: 24),
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
            Expanded(
              child: FilledButton(
                onPressed:
                    (_validate() && !_submitting) ? _submitReservation : null,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                child: Text(
                  'Submit Reservation',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked == null || picked == _date) return;

    setState(() {
      _date = picked;
      _updateBookings();
    });
  }

  Future<void> _selectStartTime(BuildContext context) async {
    TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: _start,
    );

    if (newStartTime == null || newStartTime.isAtSameTimeAs(_start)) return;

    if (!_withinOpenHours(newStartTime) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Start time not within open hours!')),
      );
    }

    setState(() {
      _start = newStartTime.roundDown(min: widget.roundMin);
      _checkTimeSpan();
    });
  }

  Future<void> _selectEndTime(BuildContext context) async {
    TimeOfDay? newEndTime = await showTimePicker(
      context: context,
      initialTime: _end,
    );

    if (newEndTime == null || newEndTime.isAtSameTimeAs(_end)) return;

    // Check if the end time is valid
    if (!_withinOpenHours(newEndTime) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: End Time must be within open hours.')),
      );
    }
    setState(() {
      _end = newEndTime.roundUp(min: widget.roundMin);
      _checkTimeSpan();
    });
  }

  void _checkTimeSpan() {
    if (_end.difference(_start).inMinutes < widget.roundMin &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: Time span must be at least ${(widget.minHours * 60).toAutoString()} Minutes.',
          ),
        ),
      );
    } else if (_end.difference(_start).inMinutes > widget.maxHours * 60 &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: Time Span must not exceed ${widget.maxHours.toAutoString()} hours.',
          ),
        ),
      );
    } else if (!_notInThePast()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: Timespan must not be more than 30 minutes in the past.',
          ),
        ),
      );
    }
  }

  bool _validateTimes() {
    int difference = _end.difference(_start).inMinutes;
    bool minTimespan = difference >= widget.minHours * 60;
    bool maxTimespan = difference <= widget.maxHours * 60;
    bool openHours = _withinOpenHours(_start) && _withinOpenHours(_end);
    return minTimespan && maxTimespan && openHours && _notInThePast();
  }

  bool _validate() {
    // all checks need to be true in order to continue
    bool participants =
        _participants.length >= _minParticipants &&
        _participants.length <= _maxParticipants;
    bool selected = _selectedRoom != null;
    bool contacts = _contacts != null;

    return _validateTimes() && participants && selected && contacts;
  }

  void _submitReservation() async {
    if (_submitting || _authToken == null) return;

    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete all fields and select between $_minParticipants and $_maxParticipants participants.',
          ),
        ),
      );
      return;
    }

    final bool isAuthenticated = await localAuth("Confirm Booking Request");
    if (!isAuthenticated) return;

    _submitting = true;

    final Account? user = await _library.getMyProfile(_authToken!);

    if (user == null) {
      _submitting = false;
      return;
    }

    final List<Student> participants =
        _participants.map<Student>((key) => _contacts![key]!).toList();

    final StreamedResponse resp = await LibraryService().postBooking(
      user,
      _selectedRoom!,
      _start,
      _end,
      _date,
      participants,
      _authToken!,
    );

    if (resp.statusCode == 401) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error: Unauthorized!")));
      }
      return;
    }

    final jsonContent = jsonDecode(await resp.stream.bytesToString());

    String message = "";

    if (resp.statusCode != 200) {
      message =
          "Booking unsuccessful: ${jsonContent['message'] ?? resp.statusCode}";
      _submitting = false;
    } else {
      final Booking b = Booking.fromJson(postBookingJson: jsonContent);
      message =
          'Booked for ${DateFormat('MMM d').format(_date)} from ${formatTime(_start)} to ${formatTime(_end)} with: ${participants.map((s) => s.name).join(', ')}, Code: ${b.bookingCode}';
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  bool _withinOpenHours(TimeOfDay dt) {
    final ttEntry =
        widget.timetable[timetableDays[_date.weekday - 1 % 7]] ?? [];

    if (ttEntry.length < 2) {
      return false;
    }
    return !dt.isBefore(ttEntry[0]) && !dt.isAfter(ttEntry[1]);
  }

  bool _notInThePast() {
    return _date
            .copyWith(hour: _end.hour, minute: _end.minute)
            .isAfter(DateTime.now()) &&
        _date
            .copyWith(hour: _start.hour, minute: _start.minute)
            .add(Duration(minutes: 31))
            .isAfter(DateTime.now());
  }
}
