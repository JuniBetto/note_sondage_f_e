import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeaderPage extends StatelessWidget implements PreferredSizeWidget {
  const HeaderPage({
    super.key,
    required this.title,
    this.closeAction,
    this.showBackButton = true, // Nuovo parametro
    this.onBackPressed,
  });

  final String title;
  final Widget? closeAction;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,

      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            )
          : null,
      centerTitle: true,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      actions: [closeAction ?? const SizedBox(width: 48)],
    );
  }
}

/*
class HeaderPage extends StatelessWidget implements PreferredSizeWidget {
  const HeaderPage({
    super.key,
    required this.title,
    this.closeAction,
    this.onBackPressed,
  });

  final String title;
  final Widget? closeAction;
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          onBackPressed != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBackPressed,
                )
              : const SizedBox(width: 48),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          closeAction ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}*/
