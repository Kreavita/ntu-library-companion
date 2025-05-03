import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/booking_stats.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/model/student.dart';
import 'package:ntu_library_companion/screens/profile/booking_stats_banner.dart';
import 'package:ntu_library_companion/widgets/centered_content.dart';
import 'package:ntu_library_companion/widgets/page_indicator.dart';
import 'package:ntu_library_companion/widgets/title_with_icon.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingHistory extends StatefulWidget {
  const BookingHistory({super.key});

  @override
  State<BookingHistory> createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory>
    with TickerProviderStateMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final LibraryService _library = LibraryService();
  AuthService? _auth;
  SettingsProvider? _settings;

  int _fetchingState = 0; // 0: not fetched, 1: fetching, 2: complete
  List<Booking> _history = [];
  List<BookingStats> _bookingStats = [];

  late PageController _pageViewController;
  late TabController _tabController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }

  void _updateCurrentPageIndex(int index) {
    _tabController.index = index;
    _pageViewController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    _tabController.index = currentPageIndex;
    setState(() {
      _currentPageIndex = currentPageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    _settings ??= Provider.of<SettingsProvider>(context);
    _auth ??= AuthService(settings: _settings!);

    if (_fetchingState == 0) fetchHistory();

    return Scaffold(
      appBar: AppBar(title: Text("Booking History")),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await fetchHistory(doFullFetch: true);
        },
        child: CenterContent(
          child:
              (_fetchingState == 1)
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    itemCount: _history.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            TitleWithIcon(
                              icon: Icons.area_chart_sharp,
                              title: "Your Statistics:",
                            ),
                            ExpandablePageView(
                              /// [PageView.scrollDirection] defaults to [Axis.horizontal].
                              /// Use [Axis.vertical] to scroll vertically.
                              controller: _pageViewController,
                              onPageChanged: _handlePageViewChanged,
                              children:
                                  _bookingStats
                                      .map(
                                        (bs) => BookingStatsBanner(stats: bs),
                                      )
                                      .toList(),
                            ),
                            PageIndicator(
                              tabController: _tabController,
                              currentPageIndex: _currentPageIndex,
                              onUpdateCurrentPageIndex: _updateCurrentPageIndex,
                            ),
                            TitleWithIcon(
                              icon: Icons.replay,
                              title: "Recent Bookings:",
                            ),
                          ],
                        );
                      }
                      return _buildBookingTile(context, _history[index - 1]);
                    },
                  ),
        ),
      ),
    );
  }

  Future<void> fetchHistory({bool doFullFetch = false}) async {
    if (_fetchingState == 1 || _fetchingState == 2) return;
    _fetchingState = doFullFetch ? 2 : 1;

    final authToken = await _auth!.getToken();

    if (authToken == null) {
      _fetchingState = 3;
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool needFullFetch = prefs.get("api_mybookings_all") != null;

    _history = await _library.getBookings(
      authToken,
      includePast: true,
      ignoreCache: doFullFetch,
    );

    _bookingStats = await _library.getBookingStats(
      authToken,
      _settings!.get('accountHolder') as Student,
      ignoreCache: doFullFetch,
    );

    if (mounted) {
      _tabController = TabController(length: _bookingStats.length, vsync: this);

      setState(() {
        _fetchingState = 3;
      });
    }

    if (!doFullFetch && needFullFetch) {
      // Replace the cached data with fresh data
      _refreshIndicatorKey.currentState?.show();
    }
  }

  Widget _buildBookingTile(context, Booking b) {
    final from = DateFormat('MMM d, HH:mm').format(b.bookingStartDate);
    final to = DateFormat('HH:mm').format(b.bookingEndDate);
    final bStatus = b.friendlyStatus(context);
    return Column(
      children: [
        ListTile(
          visualDensity: VisualDensity(vertical: 2),
          trailing: SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(bStatus.icon, color: bStatus.color, size: 32),
                Flexible(
                  child: Text(
                    bStatus.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: bStatus.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.sensor_door_outlined),
                ),
                Expanded(
                  child: Text(
                    "${SettingsProvider.type2engName[b.room.type] ?? "Room"} ${b.room.name}",
                  ),
                ),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$from - $to",
                style: TextStyle(color: Theme.of(context).hintColor),
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
                                avatar: Icon(Icons.account_circle_outlined),
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
  }
}
