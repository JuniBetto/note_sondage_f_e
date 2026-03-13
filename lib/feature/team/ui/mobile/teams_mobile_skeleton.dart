import 'package:flutter/material.dart';
import 'package:note_sondage/ui/widgets/skeleton_wrapper.dart';

/// Skeleton per la pagina TeamsMobile
class TeamsMobileSkeleton extends StatelessWidget {
  const TeamsMobileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tab bar skeleton
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 2, color: Colors.grey[400]),
            const SizedBox(height: 16),
            // View type selector skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 80,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Team cards list skeleton
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: _TeamCardMobileSkeleton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCardMobileSkeleton extends StatelessWidget {
  const _TeamCardMobileSkeleton();

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
          Row(
            children: [
              // Avatar skeleton
              const SkeletonAvatar(size: 48),
              const SizedBox(width: 12),
              // Team info skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonText(width: 140, height: 18),
                    SizedBox(height: 6),
                    SkeletonText(width: 100, height: 14),
                  ],
                ),
              ),
              // Menu button skeleton
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Members row skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonText(width: 80, height: 12),
              Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(left: index > 0 ? 0 : 0),
                    child: Transform.translate(
                      offset: Offset(-index * 8.0, 0),
                      child: const SkeletonAvatar(size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
