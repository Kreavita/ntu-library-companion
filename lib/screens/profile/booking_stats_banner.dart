import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ntu_library_companion/model/booking_stats.dart';
import 'package:ntu_library_companion/widgets/info_row.dart';

class BookingStatsBanner extends StatelessWidget {
  final BookingStats stats;
  const BookingStatsBanner({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      "Your Statistics",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  (stats.bookingLimitViolation == "N")
                      ? Row(
                        children: [
                          Icon(Icons.check, size: 24, color: Colors.green),
                          Text(
                            "No Violation",
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          Icon(Icons.block, size: 24, color: Colors.red),
                          Text(
                            "Restricted",
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                ],
              ),
              Row(
                spacing: 5,
                children: [
                  Icon(Icons.watch_later_outlined),
                  Text("Total Usage: "),
                  Expanded(
                    child: Text(
                      "${stats.bookingTotalHour} hrs, ${stats.bookingTotalCount} reservation${(stats.bookingTotalCount == 1) ? '' : 's'}",
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 5,
                children: [
                  Icon(Icons.hourglass_top_outlined),
                  Text("Current Usage: "),
                  Expanded(
                    child: Text(
                      "${stats.bookingLimitPeriodBookingHour} of ${stats.bookingLimitFrequencyCount} hrs",
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              LinearProgressIndicator(
                minHeight: 20,
                borderRadius: BorderRadius.circular(40),
                value: min(
                  max(
                    0,
                    stats.bookingLimitPeriodBookingHour /
                        stats.bookingLimitFrequencyCount,
                  ),
                  1,
                ),
              ),
              InfoRow(
                icon: Icons.info_outline,
                child: Text(
                  "The usage is limited to ${stats.bookingLimitFrequencyCount} hrs within ${stats.bookingLimitPeriodCount * 7} days",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
