import 'package:flutter/material.dart';
import 'package:note_sondage/ui/mobile/widgets/home/responsive_grid_view.dart';
import 'package:note_sondage/ui/widgets/feature_card.dart';

class HomeMobile extends StatelessWidget {
  const HomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveGridView(items: generateFeatureCards());
  }
}

List<FeatureCard> generateFeatureCards() {
  return [
    FeatureCard(
      title: 'Clock In/Out ',
      description: 'Creates impactful visuals and branding.',
      items: ['Personal attivities', 'Teams'],
      color: const Color(0xFFFF6600),
    ),
    FeatureCard(
      title: 'Sondage Tools',
      description:
          'Sondage creation and analysis tools.After you activated the virtual environment, you can run your program, and it will use the Python inside of your virtual environment with the packages you installed there',
      items: ['Teams', 'Sondage management'],
      color: const Color(0xFF0066FF),
    ),
    FeatureCard(
      title: 'Digital Marketing',
      description: 'Enhances online presence and engagement.',
      items: [
        'SEO Optimization',
        'Social Media Marketing',
        'Email Campaigns',
        'Content Creation',
        'Analytics & Reporting',
      ],
      color: const Color(0xFF33CC33),
    ),
    FeatureCard(
      title: 'App Development',
      description: 'Develops user-friendly mobile applications.',
      items: [
        'iOS Development',
        'Android Development',
        'Cross-Platform Apps',
        'UI/UX Design',
        'App Testing & Deployment',
      ],
      color: const Color(0xFFFF33AA),
    ),
    FeatureCard(
      title: 'Cloud Services',
      description: 'Provides scalable cloud solutions.',
      items: [
        'Cloud Migration',
        'Infrastructure Management',
        'Security & Compliance',
        'Backup & Recovery',
        'Cost Optimization',
      ],
      color: const Color(0xFFAA33FF),
    ),
    // Add more FeatureCards as needed
  ];
}
