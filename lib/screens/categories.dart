import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/base_api.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/api_result.dart';
import 'package:ntu_library_companion/model/auth_result.dart';
import 'package:ntu_library_companion/model/category.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/screens/categories/cat_card.dart';
import 'package:ntu_library_companion/screens/categories/cat_details.dart';
import 'package:ntu_library_companion/screens/categories/welcome_screen.dart';
import 'package:ntu_library_companion/widgets/info_row.dart';
import 'package:provider/provider.dart';

class CategoriesPage extends StatefulWidget {
  final Stream fabNotifier;

  const CategoriesPage({super.key, required this.fabNotifier});

  @override
  State<CategoriesPage> createState() => CategoriesPageState();
}

class CategoriesPageState extends State<CategoriesPage>
    with AutomaticKeepAliveClientMixin {
  StreamSubscription<dynamic>? _streamSubscription;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final LibraryService _library = LibraryService();
  late final SettingsProvider _settings = Provider.of<SettingsProvider>(
    context,
  );

  bool _loading = false;
  final Map<String, Category> _cates = {};
  final Map<String, Future<List<int>?>> _cateStats = {};

  @override
  didUpdateWidget(CategoriesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // in case the stream instance changed, subscribe to the new one
    if (widget.fabNotifier != oldWidget.fabNotifier) {
      _streamSubscription?.cancel();
      _streamSubscription = widget.fabNotifier.listen(handleFabEvent);
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _streamSubscription = widget.fabNotifier.listen(handleFabEvent);
  }

  handleFabEvent(receiver) {
    if (!mounted) return;
    if (receiver != "fetchRooms") return;
    _refreshIndicatorKey.currentState?.show();
  }

  Future<void> fetchCatesWrapper() async {
    if (_loading) return;
    _loading = true;

    await _fetchCates();

    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchCates() async {
    if (!_settings.loggedIn) return;

    final cates = await _library.getCategories(
      onResult: (res) {
        if (context.mounted && res.type != AuthResType.authOk) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(res.toString())));
        }
      },
    );

    final type2engName = {};
    final zh2engName = {};
    cates.forEach((_, cat) {
      type2engName[cat.type] = cat.engName;
      zh2engName[cat.name] = cat.engName;
    });

    _settings.updateCache("type2engName", type2engName);
    _settings.updateCache("zh2engName", zh2engName);

    final cateStats = cates.map(
      (cateId, _) => MapEntry(
        cateId,
        _fetchStats(cateId, _settings.get("authToken") ?? ""),
      ),
    );

    setState(() {
      _cates.clear();
      _cates.addAll(cates);
      _cateStats.clear();
      _cateStats.addAll(cateStats);
      if (cates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to communicate with library services!"),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    double width = MediaQuery.of(context).size.width;

    if (_settings.get("credentials") != null &&
        _cates.isEmpty &&
        !AuthService.authFailed) {
      _refreshIndicatorKey.currentState?.show() ?? fetchCatesWrapper();
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: fetchCatesWrapper,
      child: Stack(
        children: [
          if (_cates.isEmpty) WelcomeScreen(),
          if (_cates.isNotEmpty)
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InfoRow(
                    icon: Icons.info_outline,
                    child: Text("Click on a Room to make a reservation"),
                  ),
                  StaggeredGrid.count(
                    crossAxisCount: (width < 600) ? 1 : ((width < 900) ? 2 : 3),
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    children:
                        _cates.keys
                            .map(
                              (key) => StaggeredGridTile.fit(
                                crossAxisCellCount: 1,
                                child: CategoryCard(
                                  cat: _cates[key]!,
                                  stats: _cateStats[key]!,
                                  tapCallback: _openCategory,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<List<int>?> _fetchStats(String cateId, String authToken) async {
    int avail = -1;
    int total = -1;

    for (var retries = 0; retries < 10; retries++) {
      final ApiResult availRes = await _library.get(
        endpoint: Endpoint.catAvail,
        params: {"cateId": cateId},
        headers: {"authToken": authToken},
      );
      avail =
          availRes.asJson<Map<String, dynamic>>(
            fallback: {"count": -1},
          )["count"] ??
          -1;
      if (avail != -1) break;
      await Future.delayed(Duration(milliseconds: 250));
    }

    for (var retries = 0; retries < 10; retries++) {
      final ApiResult totalRes = await _library.get(
        endpoint: Endpoint.catTotal,
        params: {"miscQueryString": '{"cateId":"$cateId"}'},
        headers: {"authToken": authToken},
      );
      total =
          totalRes.asJson<Map<String, dynamic>>(
            fallback: {"count": -1},
          )["count"] ??
          -1;
      if (total != -1) break;
      await Future.delayed(Duration(milliseconds: 250));
    }

    return [avail, total];
  }

  _openCategory(String cateId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CategoryDetails(
              cate: _cates[cateId]!,
              cateStats: _cateStats[cateId]!,
            ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
}
