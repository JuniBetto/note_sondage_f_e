import 'package:flutter/material.dart';
import 'package:note_sondage/ui/widgets/skeleton_wrapper.dart';

/// Skeleton per la pagina SondageMobile
class SondageMobileSkeleton extends StatelessWidget {
  const SondageMobileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          const SkeletonText(width: 180, height: 24),
          const SizedBox(height: 8),
          const SkeletonText(width: 250, height: 14),
          const SizedBox(height: 24),
          // Survey cards skeleton
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: _SurveyCardMobileSkeleton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurveyCardMobileSkeleton extends StatelessWidget {
  const _SurveyCardMobileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Survey title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonText(width: 160, height: 18),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          const SkeletonText(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          const SkeletonText(width: 200, height: 14),
          const SizedBox(height: 16),
          // Progress bar skeleton
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonText(width: 80, height: 12),
              SkeletonText(width: 60, height: 12),
            ],
          ),
          const SizedBox(height: 16),
          // Action button skeleton
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
