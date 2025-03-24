import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/account.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/category.dart';
import 'package:ntu_library_companion/model/room.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/model/student.dart';
import 'package:ntu_library_companion/screens/reservation/participant_picker.dart';
import 'package:ntu_library_companion/screens/reservation/room_picker.dart';
import 'package:ntu_library_companion/util.dart';
import 'package:ntu_library_companion/widgets/info_row.dart';
import 'package:provider/provider.dart';

class ReservationForm extends StatefulWidget {
  final Category cate;
  final TimeTable timetable;
  final int maxHours;
  final int roundMin;

  const ReservationForm({
    super.key,
    required this.cate,
    required this.timetable,
    required this.maxHours,
    required this.roundMin,
  });

  @override
  State<ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final _formKey = GlobalKey<FormState>();
  late final SettingsProvider _settings = Provider.of<SettingsProvider>(
    context,
  );
  final LibraryService _library = LibraryService();
  AuthService? _auth;

  Map<String, Student>? _contacts;
  final Set<String> _participants = <String>{};
  DateTime _date = DateTime.now();
  Room? _selectedRoom;

  late TimeOfDay _start = TimeOfDay.fromDateTime(
    _date,
  ).roundDown(min: widget.roundMin);
  late TimeOfDay _end = _start.add(Duration(hours: 2));

  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    _auth ??= AuthService(settings: _settings);
    _contacts ??= _settings.get("contacts");

    final ttEntry =
        widget.timetable[timetableDays[_date.weekday - 1 % 7]] ?? [];
    final colors = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).viewPadding.top;

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
                                      DateFormat("EEEE,").format(_date),
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
                          "Pick between ${ttEntry[0].format(context)} "
                          "and ${ttEntry[1].format(context)}.",
                        ),
                      ),
                    if (ttEntry.length < 2)
                      InfoRow(
                        icon: Icons.event_busy_outlined,
                        child: Text("Not open on the selected date."),
                      ),
                    InfoRow(
                      icon: Icons.account_circle_outlined,
                      child: Text(
                        "Reservation duration must be between ${widget.roundMin} minutes and ${widget.maxHours} hours.",
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
                      child: Text(
                        "Select Room:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    RoomPicker(
                      authToken: _settings.get("authToken") ?? "",
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
            'Error: Time span must be at least ${widget.roundMin} Minutes.',
          ),
        ),
      );
    } else if (_end.difference(_start).inHours > widget.maxHours &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Time Span larger than allowed.')),
      );
    }
  }

  bool _validateTimes() {
    bool minTimespan = _end.difference(_start).inMinutes >= widget.roundMin;
    bool maxTimespan = _end.difference(_start).inHours <= widget.maxHours;
    bool openHours = _withinOpenHours(_start) && _withinOpenHours(_end);
    return minTimespan && maxTimespan && openHours;
  }

  bool _validate() {
    // all checks need to be true in order to continue
    bool participants = _participants.length >= 2 && _participants.length <= 7;
    bool selected = _selectedRoom != null;
    bool contacts = _contacts != null;

    return _validateTimes() && participants && selected && contacts;
  }

  void _submitReservation() async {
    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete all fields and select between 2 and 7 participants.',
          ),
        ),
      );
      return;
    }
    if (_submitting) return;
    _submitting = true;

    final authToken = await _auth!.getToken();

    if (authToken == null) {
      _submitting = false;
      return;
    }

    final Account? user = await _library.getMyAccount(authToken);

    if (user == null) {
      _submitting = false;
      return;
    }

    final List<Student> participants =
        _participants.map<Student>((key) => _contacts![key]!).toList();

    final Booking? bookingResult = await LibraryService().postBooking(
      user,
      _selectedRoom!,
      _start,
      _end,
      _date,
      participants,
      authToken,
    );

    String message = "Booking unsuccessful";

    if (bookingResult != null) {
      message =
          'Reservation booked for ${DateFormat('yyyy-MM-dd').format(_date)} from ${formatTime(_start)} to ${formatTime(_end)} with participants: ${participants.map((s) => s.name).join(', ')}';
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _withinOpenHours(TimeOfDay dt) {
    final ttEntry =
        widget.timetable[timetableDays[_date.weekday - 1 % 7]] ?? [];

    if (ttEntry.length < 2) {
      return false;
    }
    return (dt.isAfter(ttEntry[0]) || dt.isAtSameTimeAs(ttEntry[0])) &&
        (dt.isBefore(ttEntry[1]) || dt.isAtSameTimeAs(ttEntry[1]));
  }
}
