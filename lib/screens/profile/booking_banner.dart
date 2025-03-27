import 'package:flutter/material.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/screens/profile/booking_history.dart';
import 'package:ntu_library_companion/screens/reservation/reservation_info.dart';
import 'package:provider/provider.dart';

class ReservationBanner extends StatefulWidget {
  const ReservationBanner({super.key});

  @override
  State<ReservationBanner> createState() => _ReservationBannerState();
}

class _ReservationBannerState extends State<ReservationBanner> {
  final LibraryService _lib = LibraryService();

  AuthService? _auth;
  SettingsProvider? _settings;

  Booking? _booking;

  bool _fetchStarted = false;
  bool _fetchCompleted = false;

  void _fetchBookingInfo() async {
    if (_fetchStarted && !_fetchCompleted) return;

    _fetchStarted = true;
    _fetchCompleted = false;

    final token = await _auth!.getToken();

    if (token == null) {
      _fetchCompleted = true;
      return;
    }

    List<Booking> bookings = await _lib.getBookings(token);

    if (bookings.isNotEmpty) _booking = bookings.first;
    _fetchCompleted = true;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _settings ??= Provider.of<SettingsProvider>(context);
    _auth ??= AuthService(settings: _settings!);

    if (_settings?.get("credentials") != null &&
        !_fetchStarted &&
        !AuthService.authFailed) {
      _fetchBookingInfo();
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onLongPress: () {
            setState(() {
              _fetchStarted = false;
              _fetchCompleted = false;
            });
          },
          onTap: () async {
            if (_settings?.get("credentials") == null) return;

            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => BookingHistory()));
          },
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child:
                (_booking != null)
                    ? ReservationInfo(booking: _booking!)
                    : ((_fetchStarted && !_fetchCompleted)
                        ? LinearProgressIndicator()
                        : Center(
                          child: Text(
                            (_settings?.get("credentials") == null)
                                ? "Login required to view Reservations"
                                : "No Active Reservation\nLong Press to reload - Tap to view booking History",
                            textAlign: TextAlign.center,
                          ),
                        )),
          ),
        ),
      ),
    );
  }
}
