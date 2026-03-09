import 'package:flutter/material.dart';
import 'package:note_sondage/ui/widgets/skeleton_wrapper.dart';

/// Skeleton per la pagina SondageWeb
class SondageWebSkeleton extends StatelessWidget {
  const SondageWebSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          const SkeletonText(width: 200, height: 28),
          const SizedBox(height: 8),
          const SkeletonText(width: 300, height: 16),
          const SizedBox(height: 24),

          // Survey cards skeleton
          Expanded(
            child: SkeletonGrid(
              crossAxisCount: 2,
              itemCount: 4,
              childAspectRatio: 1.5,
              itemBuilder: (context, index) => SkeletonCard(
                height: 180,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SkeletonAvatar(size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SkeletonText(width: 150, height: 16),
                                SizedBox(height: 4),
                                SkeletonText(width: 100, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SkeletonText(width: double.infinity, height: 12),
                      const SizedBox(height: 8),
                      const SkeletonText(width: 200, height: 12),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          SkeletonText(width: 80, height: 32),
                          SkeletonText(width: 80, height: 32),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
