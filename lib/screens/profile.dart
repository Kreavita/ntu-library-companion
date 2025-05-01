import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/auth_result.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/conference_room.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/model/student.dart';
import 'package:ntu_library_companion/screens/profile/add_user_form.dart';
import 'package:ntu_library_companion/screens/profile/booking_banner.dart';
import 'package:ntu_library_companion/widgets/centered_content.dart';
import 'package:ntu_library_companion/widgets/confirm_dialog.dart';
import 'package:ntu_library_companion/widgets/title_with_icon.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  final Stream fabNotifier;

  const ProfilePage({super.key, required this.fabNotifier});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  StreamSubscription<dynamic>? _streamSubscription;
  SettingsProvider? _settings;
  AuthService? _auth;

  final LibraryService _api = LibraryService();
  bool _fetchCompleted = true;

  bool _updateBookingsComplete = true;
  final Map<String, Booking> _contactStates = {};
  Booking? _booking;

  Timer? _timer;

  @override
  initState() {
    super.initState();
    _streamSubscription = widget.fabNotifier.listen(handleFabEvent);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // in case the stream instance changed, subscribe to the new one
    if (widget.fabNotifier != oldWidget.fabNotifier) {
      _streamSubscription?.cancel();
      _streamSubscription = widget.fabNotifier.listen(handleFabEvent);
    }
  }

  handleFabEvent(receiver) async {
    if (!mounted || receiver != "addContact") return;

    if (_auth == null || _settings == null) return;

    final authToken = await _auth!.getToken(
      onResult: (res) {
        if (context.mounted && res.type != AuthResType.authOk) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(res.toString())));
        }
      },
    );

    if (authToken == null) return;

    if (mounted) {
      Student? result = await showDialog(
        context: context,
        builder:
            (context) => AddUserForm(
              authToken: authToken,
              studentId: _settings!.get("credentials")["user"],
            ),
      );

      if (result == null) return;

      Map<String, Student> updatedList =
          _settings!.get("contacts") ?? <String, Student>{};

      updatedList[result.uuid] = result;

      setState(() {
        _settings!.set("contacts", updatedList);
      });
    }
  }

  void _addFromHistory() async {
    if (!_fetchCompleted) return;
    Map<String, Student> updatedList =
        _settings!.get("contacts") ?? <String, Student>{};

    setState(() {
      _fetchCompleted = false;
    });

    final token = await _auth!.getToken();

    if (token == null) {
      setState(() {
        _fetchCompleted = true;
      });
      return;
    }

    final bookings = await _api.getBookings(token, includePast: true);

    for (Booking booking in bookings) {
      final participants = booking.bookingParticipants;
      for (Student participant in participants) {
        updatedList[participant.uuid] = participant;
      }
    }

    setState(() {
      _fetchCompleted = true;
      _settings!.set("contacts", updatedList);
    });
  }

  void _updateBookingInfos({bool shadowUpdate = false}) async {
    if (!_updateBookingsComplete) return;

    setState(() {
      if (!shadowUpdate) {
        _booking = null;
      }
      _updateBookingsComplete = false;
    });

    final token = await _auth!.getToken();

    await () async {
      if (token == null) return;

      final Map<String, Student> contacts = _settings?.get("contacts") ?? {};
      final String userAccount = _settings?.get("credentials")?["user"] ?? "";

      if (contacts.isEmpty) return;

      final now = DateTime.now();
      final Map<String, Booking> newStates = {};

      Map<ConferenceRoom, List<Booking>> confRoomBookings = await _api
          .getConfRoomBookings(token, now, now.add(Duration(days: 1)));

      confRoomBookings.forEach((room, bookings) {
        for (final booking in bookings) {
          List<String> participantIds =
              booking.bookingParticipants.map((s) => s.uuid).toList() +
              [booking.host.uuid];

          List<String> participantAccounts =
              booking.bookingParticipants
                  .map((s) => s.account.toLowerCase())
                  .toList() +
              [booking.host.account.toLowerCase()];

          if (participantAccounts.contains(userAccount.toLowerCase())) {
            _booking = booking;
            _booking!.bookingParticipants.add(
              Student(
                uuid: booking.host.uuid,
                account: booking.host.account,
                name: booking.host.name,
              ),
            );
            _booking!.bookingParticipants.sort(
              (s1, s2) => s1.name.compareTo(s2.name),
            );
          }

          for (var uuid in contacts.keys) {
            if (!participantIds.contains(uuid)) continue;
            if (booking.bookingEndDate.isBefore(DateTime.now())) continue;
            if (booking.bookingStartDate.isAfter(DateTime.now())) continue;

            newStates[uuid] = booking;
          }

          if (contacts.length == newStates.length) return;
        }
      });

      _contactStates.clear();
      _contactStates.addAll(newStates);
    }();

    setState(() {
      _updateBookingsComplete = true;
    });

    if (_booking == null && token != null) {
      setState(() {
        _updateBookingsComplete = false;
      });

      _booking = (await _api.getBookings(token)).firstOrNull;

      setState(() {
        _updateBookingsComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    _settings ??= Provider.of<SettingsProvider>(context);
    _auth ??= AuthService(settings: _settings!);

    if (_timer == null) {
      _timer = Timer.periodic(Duration(minutes: 7), (Timer timer) {
        _updateBookingInfos(shadowUpdate: true);
      });
      _updateBookingInfos();
    }

    final Map<String, Student> contacts = _settings!.get("contacts") ?? {};
    final keys = contacts.keys.toList();

    return CenterContent(
      child: Column(
        children: [
          ReservationBanner(
            onRefresh: _updateBookingInfos,
            booking: _booking,
            loggedIn: _settings!.get("credentials") != null,
            finishedRequest: _updateBookingsComplete,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: TitleWithIcon(icon: Icons.people, title: "Contacts:"),
              ),
            ],
          ),
          Expanded(
            child:
                (keys.isEmpty)
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8.0,
                      children: [
                        Icon(Icons.group_off_outlined, size: 36),
                        Text(
                          "No Contacts added",
                          style: TextStyle(fontSize: 20),
                        ),
                        OutlinedButton(
                          onPressed: _fetchCompleted ? _addFromHistory : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 8,
                            children: [
                              _fetchCompleted
                                  ? Icon(Icons.auto_mode_outlined)
                                  : CircularProgressIndicator.adaptive(),
                              Flexible(child: Text("Import From History")),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            spacing: 16.0,
                            children: const [
                              Icon(Icons.person_add_outlined),
                              Expanded(
                                child: Text(
                                  "Many offerings can only be booked by a group of people. Add your fellow library-goers by tapping the Button below. (Login required)",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, i) {
                        final Student c = contacts[keys[i]]!;
                        final initials = c.name
                            .split(" ")
                            .map((el) => el[0])
                            .join("");

                        String roomInfo = "";

                        if (_contactStates.containsKey(c.uuid)) {
                          roomInfo =
                              " – Room ${_contactStates[c.uuid]!.room.name}";
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              initials.substring(0, min(initials.length, 3)),
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () async {
                              bool deleteToken = await showDialog(
                                context: context,
                                builder:
                                    (context) => ConfirmDialog(
                                      title: "Delete Contact?",
                                      content:
                                          "Delete ${c.name}? You will need their Student ID to add them again.",
                                      confirmString: "Delete",
                                      icon: Icons.logout,
                                    ),
                              );
                              if (deleteToken) {
                                setState(() {
                                  contacts.remove(keys[i]);
                                  _settings!.set("contacts", contacts);
                                });
                              }
                            },
                            icon: Icon(Icons.person_remove_outlined),
                          ),
                          title: Text(c.name),
                          subtitle: Text(c.account + roomInfo),
                          onTap: () {},
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
