import 'package:flutter/material.dart';

class EsketitDrawer extends StatelessWidget {
  const EsketitDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          TextButton.icon(
            style: ButtonStyle(alignment: Alignment.centerLeft),
            onPressed: () {},
            icon: Icon(Icons.settings_rounded),
            label: Text(
              // TODO: localize it.
              'Settings',
            ),
          ),
        ],
      ),
    );
  }
}
