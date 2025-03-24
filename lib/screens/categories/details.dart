import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ntu_library_companion/model/category.dart';
import 'package:ntu_library_companion/util.dart';
import 'package:ntu_library_companion/screens/reservation/reservation_form.dart';
import 'package:ntu_library_companion/widgets/timetable.dart';

class RoomDetailsWidget extends StatefulWidget {
  final Category cate;

  const RoomDetailsWidget({super.key, required this.cate});

  @override
  State<RoomDetailsWidget> createState() => _RoomDetailsWidgetState();
}

class _RoomDetailsWidgetState extends State<RoomDetailsWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<TimeTable> _openInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _openInfo = parseOpenInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TimeTable> parseOpenInfo() {
    final List<TimeTable> collection = [];
    final List<String> openingModes = ["", "Exam", "Vacation", "Holiday"];

    final json = widget.cate.openPolicy;
    for (var mode in openingModes) {
      TimeTable modeTable = {};
      for (var i = 0; i < timetableDays.length; i++) {
        List<TimeOfDay> times = [];
        for (var time in ["Start", "End"]) {
          final day = timetableDays[i].substring(0, 3).toLowerCase();
          String? timeStr = json["$day${mode}Open${time}Time"];
          int hour = -1, min = 0;
          if (timeStr != null) {
            hour = int.parse(timeStr.substring(0, 2));
            min = int.parse(timeStr.substring(2, 4));
          } else if (json["${timetableDays[i]}${mode}OpenStartHour"] != null) {
            hour = json["${timetableDays[i]}${mode}OpenStartHour"];
          }
          if (hour != -1) times.add(TimeOfDay(hour: hour, minute: min));
        }
        modeTable[timetableDays[i]] = (times.length == 2) ? times : [];
      }
      collection.add(modeTable);
    }

    return collection;
  }

  void reserve() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ReservationForm(
              timetable: _openInfo[0],
              maxHours: 3,
              cate: widget.cate,
              roundMin: 30,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).viewPadding.top;
    final cate = widget.cate;
    return Scaffold(
      body: SingleChildScrollView(
        child: SelectableRegion(
          selectionControls: MaterialTextSelectionControls(),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Padding(padding: EdgeInsets.only(top: topPadding)),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      cate.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (cate.attachmentId != "")
                    CachedNetworkImage(
                      imageUrl:
                          "https://sms.lib.ntu.edu.tw/rest/council/common/resourceCates/${cate.catId}/attachs/${cate.attachmentId}/file",
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        cate.description,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Open Hours",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    tabs: [
                      Tab(text: 'Regular'),
                      Tab(text: 'Exam'),
                      Tab(text: 'Vacations'),
                      Tab(text: 'Holidays'),
                    ],
                    onTap: (index) {
                      setState(() {
                        //_tabController.index = index;
                      });
                    },
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: IndexedStack(
                      key: ValueKey<int>(_tabController.index),
                      index: _tabController.index,
                      children:
                          _openInfo
                              .map((tt) => Timetable(openHours: tt))
                              .toList(),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Booking Information",
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        cate.bookingEngDesc,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 20,
        child: Container(
          color: Theme.of(context).bottomAppBarTheme.color,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
                  onPressed: reserve,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  child: Text(
                    'Reserve (${cate.available}/${cate.capacity})',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
