import 'package:flutter/material.dart';
import 'package:note_sondage/ui/widgets/skeleton_wrapper.dart';

/// Skeleton per la pagina RolePageWeb
class RolePageWebSkeleton extends StatelessWidget {
  const RolePageWebSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 1200,
              maxHeight: constraints.maxHeight * 0.88,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Left panel - Role list
                  Expanded(
                    child: Column(
                      children: [
                        const SkeletonText(width: 150, height: 28),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SkeletonList(
                            itemCount: 6,
                            itemBuilder: (context, index) => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: SkeletonCard(
                                height: 60,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      SkeletonAvatar(size: 36),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SkeletonText(
                                              width: 120,
                                              height: 14,
                                            ),
                                            SizedBox(height: 4),
                                            SkeletonText(width: 80, height: 10),
                                          ],
                                        ),
                                      ),
                                      SkeletonText(width: 24, height: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right panel - Create role
                  Expanded(
                    child: Column(
                      children: [
                        const SkeletonText(width: 150, height: 28),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SkeletonCard(
                            height: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SkeletonText(width: 100, height: 16),
                                  const SizedBox(height: 8),
                                  const SkeletonText(
                                    width: double.infinity,
                                    height: 48,
                                  ),
                                  const SizedBox(height: 24),
                                  const SkeletonText(width: 120, height: 16),
                                  const SizedBox(height: 8),
                                  // Permission checkboxes skeleton
                                  ...List.generate(
                                    5,
                                    (index) => const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          SkeletonText(width: 24, height: 24),
                                          SizedBox(width: 12),
                                          SkeletonText(width: 150, height: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const SkeletonText(
                                    width: double.infinity,
                                    height: 48,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
