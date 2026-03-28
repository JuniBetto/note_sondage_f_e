import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class StatusClocking extends StatelessWidget {
  const StatusClocking({super.key, this.isCompact = false});
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${localization.clockedInAt} 9:00 AM"),
                SizedBox(height: 10.0), // height per Column, non width
                Text("${localization.startBreakAt} 5:00 PM"),
                SizedBox(height: 10.0), // height per Column, non width
                Text("${localization.endBreakAt} 9:00 AM"),
                SizedBox(height: 10.0), // height per Column, non width
                Text("${localization.clockedOutAt} 5:00 PM"),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${localization.clockedInAt} 9:00 AM"),
                    SizedBox(height: 10.0), // width per Row
                    Text("${localization.startBreakAt} 5:00 PM"),
                  ],
                ),

                SizedBox(width: 10.0), // height per Column, non width

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${localization.endBreakAt} 9:00 AM"),
                    SizedBox(height: 10.0), // width per Row
                    Text("${localization.clockedOutAt} 5:00 PM"),
                  ],
                ),
              ],
            ),
    );
  }
}
