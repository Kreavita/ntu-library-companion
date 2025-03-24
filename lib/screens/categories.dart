import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/library_service.dart';
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
  late final AuthService _auth = AuthService(settings: _settings);

  bool _loading = false;
  final Map<String, Category> _cates = {};

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
    if (_loading) {
      print("already loading");
      return;
    }
    _loading = true;

    await _fetchCates();

    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchCates() async {
    final authToken = await _auth.getToken(
      onResult: (res) {
        if (context.mounted && res.type != AuthResType.authOk) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(res.toString())));
        }
      },
    );

    if (authToken == null) return;

    final cates = await _library.getCategories(authToken);

    setState(() {
      _cates.clear();
      _cates.addAll(cates);
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
      _refreshIndicatorKey.currentState?.show();
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

  _openCategory(String cateId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryDetails(cate: _cates[cateId]!),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
