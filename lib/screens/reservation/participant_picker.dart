import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ntu_library_companion/model/student.dart';
import 'package:ntu_library_companion/widgets/info_row.dart';

class ParticipantPicker extends StatelessWidget {
  final Map<String, Student> contacts;
  final Set<String> participants;
  final void Function(String key) onDelete;
  final void Function(String key) onAdd;

  const ParticipantPicker({
    super.key,
    required this.contacts,
    required this.participants,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keys = contacts.keys.toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
            border: Border.all(width: 1, color: colors.onSurface),
          ),
          child:
              (participants.isEmpty)
                  ? InfoRow(
                    icon: Icons.info_outline,
                    child: Text("Selected Participants will appear here."),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 2),

                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      spacing: 5.0,
                      children:
                          participants.map((i) {
                            return Chip(
                              avatar: Icon(Icons.account_circle_outlined),
                              label: Text(contacts[i]!.name),
                              onDeleted: () => onDelete(i),
                            );
                          }).toList(),
                    ),
                  ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15.0)),
            border: Border.all(color: colors.onSurface),
          ),
          height: 200,
          child:
              (keys.isEmpty)
                  ? SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "No contacts to add",
                          style: TextStyle(fontSize: 20),
                        ),
                        InfoRow(
                          icon: Icons.person_add_outlined,
                          child: Text(
                            "You need to add them on the profile screen first.",
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, i) {
                      final p = contacts[keys[i]]!;
                      if (participants.contains(keys[i])) {
                        return SizedBox.shrink();
                      }
                      final initials = p.name
                          .split(" ")
                          .map((el) => el[0])
                          .join("");
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            initials.substring(0, min(3, initials.length)),
                          ),
                        ),
                        trailing: Icon(Icons.add),
                        title: Text(p.name),
                        subtitle: Text(p.account),
                        onTap: () => onAdd(keys[i]),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
