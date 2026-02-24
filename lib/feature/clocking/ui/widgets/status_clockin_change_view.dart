import 'package:flutter/material.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/clockin_track.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class StatusClockInChangeView extends StatefulWidget {
  const StatusClockInChangeView({super.key, this.isMobile = false});
  final bool isMobile;

  @override
  State<StatusClockInChangeView> createState() =>
      _StatusClockInChangeViewState();
}

class _StatusClockInChangeViewState extends State<StatusClockInChangeView> {
  bool isClockedTeamWithUsers = true;

  void _onStatusChanged(String? value) {
    // Handle status change logic here
    print("Selected status: $value");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: widget.isMobile ? 200 : 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Search team or member",
                      style: textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CustomInputField(
                      hintText: "Email or team name",
                      controller: TextEditingController(),
                      validator: emailValidator,
                      isSearch: true,
                      onSearchPressed: () {
                        // Handle search action
                      },
                    ),
                  ],
                ),
              ),
              Spacer(),
              SizedBox(
                width: widget.isMobile ? 140 : 250,
                child: GenericDropdownFormField<String>(
                  label: "",
                  style: theme.textTheme.bodyMedium,
                  items: listStatusClockCheck,
                  value: listStatusClockCheck.first,
                  displayText: (status) => status,
                  valueGetter: (status) => status,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        isClockedTeamWithUsers = value == "Team with users"
                            ? true
                            : false;
                      });
                    }
                    _onStatusChanged(value);
                  },

                  hintText: localization.status,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a status';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),

          SizedBox(height: 30.0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ClockInTrack(
                    isTeamWithUsers: isClockedTeamWithUsers,
                    title: '',
                    isMobile: widget.isMobile,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
