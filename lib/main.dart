import 'dart:async';

import 'package:flutter/material.dart';
import 'package:json_store/json_store.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:provider/provider.dart';

import 'screens/categories.dart';
import 'screens/profile.dart';
import 'screens/settings.dart';

void main() async {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NTU Library Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness:
              Provider.of<SettingsProvider>(context).get('darkMode') ?? false
                  ? Brightness.dark
                  : Brightness.light,
        ),
      ),
      home: MyHomePage(title: 'NTU Library Companion'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final JsonStore jsonStore = JsonStore();

  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final _fabNotifier = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    SettingsProvider settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    jsonStore.getItem('settings').then((jsonObj) {
      settings.loadJson(jsonObj: jsonObj ?? {}, jsonStore: jsonStore);
      setState(() {});
    });

    //WidgetsBinding.instance.addPostFrameCallback((_) async {final jsonObj = await });
  }

  // List of widgets for each tab
  late final List<StatefulWidget> _widgetOptions = [
    CategoriesPage(fabNotifier: _fabNotifier.stream),
    ProfilePage(fabNotifier: _fabNotifier.stream),
    SettingsPage(),
  ];

  late final List<Widget?> _buttonOptions = [
    FloatingActionButton(
      onPressed: () {
        if (isLoggedIn()) {
          _fabNotifier.sink.add("fetchRooms");
        }
      },
      tooltip: 'Refresh',
      child: const Icon(Icons.refresh),
    ),
    FloatingActionButton(
      onPressed: () {
        if (isLoggedIn()) {
          _fabNotifier.sink.add("addContact");
        }
      },
      tooltip: 'Add Contact',
      child: const Icon(Icons.person_add_outlined),
    ),
    null,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        leading: const Icon(Icons.book_sharp, size: 32),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index when swiping
          });
        },
        children: _widgetOptions,
      ),
      floatingActionButton: _buttonOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.room), label: 'Rooms'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  bool isLoggedIn() {
    SettingsProvider settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    bool loggedIn = settings.get("credentials") != null;
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You need to be logged in to do that.")),
      );
    }
    return loggedIn;
  }
}
