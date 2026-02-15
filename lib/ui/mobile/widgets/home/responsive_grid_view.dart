import 'package:flutter/material.dart';
import 'package:note_sondage/ui/widgets/feature_card.dart';

class ResponsiveGridView extends StatefulWidget {
  const ResponsiveGridView({super.key, required this.items});
  final List<FeatureCard> items;

  @override
  ResponsiveGridViewState createState() => ResponsiveGridViewState();
}

class ResponsiveGridViewState extends State<ResponsiveGridView> {
  @override
  @override
  Widget build(BuildContext context) {
    return viewScrollWebMobile(widget.items);
  }
}

Widget viewScrollWebMobile(List<FeatureCard> items) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Wrap(
        runSpacing: 8.0,
        spacing: 8.0,
        children: items
            .map(
              (item) => FeatureCard(
                title: item.title,
                description: item.description,
                items: item.items,
                color: item.color,
              ),
            )
            .toList(),
      ),
    ),
  );
}
