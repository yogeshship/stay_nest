import 'package:flutter/material.dart';

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard(
      {super.key,
      required this.label,
      required this.value,
      required this.icon});
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          leading: Icon(icon),
          title:
              Text('$value', style: Theme.of(context).textTheme.headlineSmall),
          subtitle: Text(label)));
}
