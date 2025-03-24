import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/api/base_api.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/category.dart';
import 'package:ntu_library_companion/model/room.dart';
import 'package:ntu_library_companion/util.dart';
import 'package:ntu_library_companion/widgets/info_row.dart';

class RoomPicker extends StatefulWidget {
  final String authToken;
  final Category cate;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool validSelection;

  final Function(Room? selectedRoom) onTap;

  const RoomPicker({
    super.key,
    required this.authToken,
    required this.cate,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.onTap,
    required this.validSelection,
  });

  @override
  State<RoomPicker> createState() => _RoomPickerState();
}

class _RoomPickerState extends State<RoomPicker> {
  final _api = LibraryService();

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<Room> _rooms = [];
  String _selectedRid = "";

  @override
  Widget build(BuildContext context) {
    _updateRoomsList(context);
    ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: scheme.onSurface),
      ),
      height: 200,
      child:
          (_rooms.isEmpty || !widget.validSelection)
              ? Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child:
                      (widget.validSelection)
                          ? InfoRow(
                            icon: Icons.no_meeting_room_outlined,
                            child: Text(
                              "No Rooms found for the current configuration",
                            ),
                          )
                          : InfoRow(
                            icon: Icons.info_outline,
                            child: Text(
                              "Rooms will be searched when you have set a valid timespan",
                            ),
                          ),
                ),
              )
              : ListView.builder(
                itemCount: _rooms.length,
                itemBuilder: (context, i) {
                  final room = _rooms[i];
                  return ListTile(
                    style:
                        ListTileTheme.of(
                          context,
                        ).copyWith(tileColor: scheme.secondaryContainer).style,
                    leading: CircleAvatar(
                      child: Icon(Icons.meeting_room_outlined),
                    ),
                    trailing:
                        (room.rid == _selectedRid)
                            ? Icon(
                              Icons.check_circle_outline,
                              color: scheme.primary,
                            )
                            : Icon(Icons.circle_outlined),
                    title: Text(room.name),
                    subtitle: Text(room.floor),
                    onTap: () {
                      _selectedRid = room.rid;
                      widget.onTap(room);
                    },
                  );
                },
              ),
    );
  }

  void _updateRoomsList(BuildContext context) async {
    if (_date == widget.date &&
        _startTime == widget.startTime &&
        _endTime == widget.endTime) {
      return;
    }

    if (widget.authToken == "" || !widget.validSelection) {
      return;
    }

    _date = widget.date;
    _startTime = widget.startTime;
    _endTime = widget.endTime;

    String date = DateFormat("y/MM/dd").format(_date!);

    final jsonResp = await _api.get(
      endpoint: Endpoint.availRooms,
      json: true,
      headers: {"authToken": widget.authToken},
      params: {
        "bookingStartDate": "$date ${formatTime(_startTime!)}:00",
        "bookingEndDate": "$date ${formatTime(_endTime!)}:00",
        "cateId": widget.cate.catId,
      },
    );

    if (jsonResp.runtimeType != List && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: Couldnt get rooms.')));
    }

    _rooms.clear();
    _rooms.addAll(jsonResp.map<Room>((o) => Room.fromJson(o)));

    if (!_rooms.any((room) => room.rid == _selectedRid)) {
      widget.onTap(null);
    }
  }
}
