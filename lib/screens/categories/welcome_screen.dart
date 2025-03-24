import 'package:flutter/material.dart';
import 'package:ntu_library_companion/widgets/centered_content.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CenterContent(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Welcome to the NTU Library Companion App!",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: const [
                    Icon(Icons.login),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8)),
                    Expanded(
                      child: Text(
                        "To make reservations and see available rooms and their capacites, you need to log in to your NTU account in the settings pane.",
                      ),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: const [
                    Icon(Icons.no_accounts),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8)),
                    Expanded(
                      child: Text(
                        "Your Login information are solely used to communicate with the library website and otherwise remain on this device only.",
                      ),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: const [
                    Icon(Icons.arrow_forward),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8)),
                    Expanded(
                      child: Text(
                        "Swipe to the right to view your recent roommates.",
                      ),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
