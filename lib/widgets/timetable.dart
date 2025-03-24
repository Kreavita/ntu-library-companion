import 'package:flutter/material.dart';
import 'package:ntu_library_companion/util.dart';

class Timetable extends StatelessWidget {
  final Map<String, List<TimeOfDay>> openHours;

  const Timetable({super.key, required this.openHours});

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          openHours
              .map((day, hours) => MapEntry(day, buildSingleRow(day, hours)))
              .values
              .toList(),
    );
  }

  Widget buildSingleRow(day, hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Row(
        children: [
          Expanded(child: Text("$day:", textAlign: TextAlign.right)),
          Padding(padding: EdgeInsets.symmetric(horizontal: 8)),
          Expanded(
            child: Text(
              hours.isNotEmpty
                  ? '${formatTime(hours[0])} - ${formatTime(hours[1])}'
                  : 'Closed',
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  ListView buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: openHours.keys.length,
      itemBuilder: (context, index) {
        String day = openHours.keys.elementAt(index);
        List<TimeOfDay> hours = openHours[day] ?? [];

        String displayHours =
            hours.isNotEmpty
                ? '${formatTime(hours[0])} - ${formatTime(hours[1])}'
                : 'Closed';

        return ListTile(title: Text(day), trailing: Text(displayHours));
      },
    );
  }
}
