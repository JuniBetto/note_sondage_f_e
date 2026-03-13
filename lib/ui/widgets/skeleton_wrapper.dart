import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Widget wrapper per gestire lo stato di loading con skeleton.
///
/// Uso:
/// ```dart
/// SkeletonWrapper(
///   isLoading: state.isLoading,
///   child: YourContent(),
///   skeleton: YourSkeletonContent(), // opzionale
/// )
/// ```
class SkeletonWrapper extends StatelessWidget {
  const SkeletonWrapper({
    super.key,
    required this.isLoading,
    required this.child,
    this.skeleton,
    this.ignoreContainers = false,
    this.justifyMultiLineText = false,
    this.containersColor,
    this.effect,
  });

  /// Se true, mostra lo skeleton
  final bool isLoading;

  /// Il contenuto da mostrare quando non è in loading
  final Widget child;

  /// Widget skeleton personalizzato (opzionale)
  /// Se non fornito, usa il child come base per lo skeleton
  final Widget? skeleton;

  /// Se true, ignora i container e mostra solo il testo
  final bool ignoreContainers;

  /// Se true, giustifica il testo multilinea
  final bool justifyMultiLineText;

  /// Colore dei container skeleton
  final Color? containersColor;

  /// Effetto di animazione personalizzato
  final PaintingEffect? effect;

  @override
  Widget build(BuildContext context) {
    // Se è in loading e abbiamo uno skeleton personalizzato, mostralo direttamente
    if (isLoading && skeleton != null) {
      return skeleton!;
    }

    // Altrimenti usa Skeletonizer per animare il child
    return Skeletonizer(
      enabled: isLoading,
      ignoreContainers: ignoreContainers,
      justifyMultiLineText: justifyMultiLineText,
      containersColor: containersColor,
      effect: effect ?? const ShimmerEffect(),
      child: child,
    );
  }
}

/// Widget per creare placeholder di testo skeleton
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.width = 100,
    this.height = 16,
    this.borderRadius = 4,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Widget per creare placeholder di card skeleton
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.width,
    this.height = 100,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.all(16),
    this.child,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          child ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonText(width: 150, height: 20),
              const SizedBox(height: 12),
              const SkeletonText(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              const SkeletonText(width: 200, height: 14),
            ],
          ),
    );
  }
}

/// Widget per creare placeholder di avatar skeleton
class SkeletonAvatar extends StatelessWidget {
  const SkeletonAvatar({super.key, this.size = 48, this.isCircle = true});

  final double size;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(8),
      ),
    );
  }
}

/// Widget per creare placeholder di lista skeleton
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.titleWidth = 150,
    this.subtitleWidth = 100,
  });

  final bool hasLeading;
  final bool hasTrailing;
  final double titleWidth;
  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          if (hasLeading) ...[
            const SkeletonAvatar(size: 40),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: titleWidth, height: 16),
                const SizedBox(height: 8),
                SkeletonText(width: subtitleWidth, height: 12),
              ],
            ),
          ),
          if (hasTrailing) const SkeletonText(width: 60, height: 24),
        ],
      ),
    );
  }
}

/// Widget per creare una lista di skeleton items
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
    this.separator,
  });

  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;
  final Widget? separator;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          separator ?? const Divider(height: 1),
      itemBuilder: itemBuilder ?? (context, index) => const SkeletonListTile(),
    );
  }
}

/// Widget per creare una griglia di skeleton items
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.padding = const EdgeInsets.all(16),
    this.itemBuilder,
  });

  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets padding;
  final Widget Function(BuildContext, int)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder ?? (context, index) => const SkeletonCard(),
    );
  }
}

/// Widget per creare un skeleton di tabella
class SkeletonTable extends StatelessWidget {
  const SkeletonTable({
    super.key,
    this.rowCount = 5,
    this.columnCount = 4,
    this.headerHeight = 48,
    this.rowHeight = 56,
  });

  final int rowCount;
  final int columnCount;
  final double headerHeight;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          height: headerHeight,
          color: Colors.grey[100],
          child: Row(
            children: List.generate(
              columnCount,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SkeletonText(width: 80, height: 14),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // Rows
        ...List.generate(
          rowCount,
          (rowIndex) => Column(
            children: [
              Container(
                height: rowHeight,
                child: Row(
                  children: List.generate(
                    columnCount,
                    (colIndex) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SkeletonText(
                          width: colIndex == 0 ? 120 : 80,
                          height: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (rowIndex < rowCount - 1) const Divider(height: 1),
            ],
          ),
        ),
      ],
    );
  }
}
