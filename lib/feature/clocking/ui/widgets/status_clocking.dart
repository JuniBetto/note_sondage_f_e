import 'package:flutter/material.dart';

class StatusClocking extends StatelessWidget {
  const StatusClocking({super.key, this.isCompact = false});
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Clocked in at: 9:00 AM"),
                SizedBox(height: 10.0), // height per Column, non width
                Text("Start break at: 5:00 PM"),
                SizedBox(height: 10.0), // height per Column, non width
                Text("End break at: 9:00 AM"),
                SizedBox(height: 10.0), // height per Column, non width
                Text("Clocked out at: 5:00 PM"),
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
                    Text("Clocked in at: 9:00 AM"),
                    SizedBox(height: 10.0), // width per Row
                    Text("Start break at: 5:00 PM"),
                  ],
                ),

                SizedBox(width: 10.0), // height per Column, non width

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("End break at: 9:00 AM"),
                    SizedBox(height: 10.0), // width per Row
                    Text("Clocked out at: 5:00 PM"),
                  ],
                ),
              ],
            ),
    );
  }
}
