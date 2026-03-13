import 'package:flutter/material.dart';
import 'package:note_sondage/ui/widgets/skeleton_wrapper.dart';

/// Skeleton per la pagina ClockingMobile
class ClockingMobileSkeleton extends StatelessWidget {
  const ClockingMobileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Title skeleton
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SkeletonText(width: 200, height: 16),
            ),
            Divider(height: 4, color: Colors.grey[300]),
            const SizedBox(height: 16),
            // Status row skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Button skeleton
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 4, color: Colors.grey[300]),
            const SizedBox(height: 16),
            // Status change view skeleton
            Expanded(
              child: Column(
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonText(width: 100, height: 14),
                      SkeletonText(width: 80, height: 14),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // List items skeleton
                  Expanded(
                    child: ListView.builder(
                      itemCount: 4,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _StatusItemSkeleton(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItemSkeleton extends StatelessWidget {
  const _StatusItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonText(width: 120, height: 14),
                SizedBox(height: 4),
                SkeletonText(width: 80, height: 12),
              ],
            ),
          ),
          const SkeletonText(width: 60, height: 12),
        ],
      ),
    );
  }
}
