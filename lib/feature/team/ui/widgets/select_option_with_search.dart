import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:uuid/uuid.dart';

const _kDefaultBorderRadius = 12.0;

/// Widget generico per selezione singola (dropdown classico)
class GenericDropdownFormField<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) displayText;
  final dynamic Function(T) valueGetter;
  final ValueChanged<dynamic> onChanged;
  final FormFieldValidator<dynamic>? validator;
  final String hintText;
  final bool isExpanded;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final bool isDense;
  final Color? fillColor;
  final bool filled;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final Color? dropdownColor;
  final int? elevation;
  final double? iconSize;
  final Color? iconColor;
  final bool enableFeedback;

  const GenericDropdownFormField({
    Key? key,
    required this.label,
    required this.items,
    required this.value,
    required this.displayText,
    required this.valueGetter,
    required this.onChanged,
    this.validator,
    this.hintText = 'Select an option',
    this.isExpanded = true,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.border,
    this.isDense = false,
    this.fillColor,
    this.filled = false,
    this.style,
    this.hintStyle,
    this.dropdownColor,
    this.elevation,
    this.iconSize,
    this.iconColor,
    this.enableFeedback = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
          ),
        DropdownButtonFormField<dynamic>(
          value: value != null ? valueGetter(value as T) : null,
          items: items.map((T item) {
            return DropdownMenuItem<dynamic>(
              alignment: AlignmentGeometry.centerLeft,
              value: valueGetter(item),
              child: Text(
                displayText(item),
                style: style ?? TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: isExpanded,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: hintStyle ?? TextStyle(color: Colors.grey[600]),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding:
                contentPadding ??
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border:
                border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
                  borderSide: BorderSide(color: colorScheme.bottomOutline!),
                ),
            enabledBorder:
                border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
                  borderSide: BorderSide(color: colorScheme.bottomOutline!),
                ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
              borderSide: BorderSide(
                color: colorScheme.selectionColor!,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            filled: filled,
            fillColor: fillColor ?? Theme.of(context).cardColor,
            isDense: isDense,
          ),
          dropdownColor: dropdownColor,
          elevation: elevation ?? 8,
          iconSize: iconSize ?? 24,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: iconColor ?? Colors.grey[600],
          ),
          iconEnabledColor: iconColor ?? Colors.grey[600],
          iconDisabledColor: Colors.grey[400],
          style: style ?? TextStyle(fontSize: 16, color: Colors.black87),
          enableFeedback: enableFeedback,
        ),
      ],
    );
  }
}

/// Widget generico per selezione multipla con chip e dialog
class GenericMultiSelectDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) displayText;
  final dynamic Function(T) valueGetter;
  final ValueChanged<List<T>> onChanged;
  final FormFieldValidator<List<T>>? validator;
  final String hintText;
  final String dialogTitle;
  final String searchHintText;
  final bool enableSearch;
  final EdgeInsetsGeometry? contentPadding;
  final bool isDense;
  final Color? fillColor;
  final bool filled;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final Color? chipColor;
  final Color? chipTextColor;
  final int? maxChipsVisible;

  const GenericMultiSelectDropdown({
    Key? key,
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.displayText,
    required this.valueGetter,
    required this.onChanged,
    this.validator,
    this.hintText = 'Select options',
    this.dialogTitle = 'Select options',
    this.searchHintText = 'Search...',
    this.enableSearch = true,
    this.contentPadding,
    this.isDense = false,
    this.fillColor,
    this.filled = false,
    this.style,
    this.hintStyle,
    this.chipColor,
    this.chipTextColor,
    this.maxChipsVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FormField<List<T>>(
      initialValue: selectedItems,
      validator: validator,
      builder: (FormFieldState<List<T>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
            InkWell(
              onTap: () => _showMultiSelectDialog(context, state),
              borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: selectedItems.isEmpty ? hintText : null,
                  hintStyle: hintStyle ?? TextStyle(color: Colors.grey[600]),
                  contentPadding:
                      contentPadding ??
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
                    borderSide: BorderSide(color: colorScheme.bottomOutline!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
                    borderSide: BorderSide(color: colorScheme.bottomOutline!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
                    borderSide: BorderSide(
                      color: colorScheme.selectionColor!,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  errorText: state.errorText,
                  filled: filled,
                  fillColor: fillColor ?? Theme.of(context).cardColor,
                  isDense: isDense,
                  suffixIcon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.grey[600],
                  ),
                ),
                child: selectedItems.isEmpty
                    ? Text(
                        hintText,
                        style: hintStyle ?? TextStyle(color: Colors.grey[600]),
                      )
                    : _buildChipsDisplay(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChipsDisplay(BuildContext context) {
    final theme = Theme.of(context);
    final displayItems =
        maxChipsVisible != null && selectedItems.length > maxChipsVisible!
        ? selectedItems.take(maxChipsVisible!).toList()
        : selectedItems;
    final remainingCount =
        maxChipsVisible != null && selectedItems.length > maxChipsVisible!
        ? selectedItems.length - maxChipsVisible!
        : 0;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...displayItems.map(
          (item) => Chip(
            label: Text(
              displayText(item),
              style: TextStyle(
                fontSize: 12,
                color: chipTextColor ?? theme.colorScheme.onPrimary,
              ),
            ),
            backgroundColor: chipColor ?? theme.colorScheme.primary,
            deleteIcon: Icon(
              Icons.close,
              size: 16,
              color: chipTextColor ?? theme.colorScheme.onPrimary,
            ),
            onDeleted: () {
              final newList = List<T>.from(selectedItems)..remove(item);
              onChanged(newList);
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        if (remainingCount > 0)
          Chip(
            label: Text(
              '+$remainingCount',
              style: TextStyle(
                fontSize: 12,
                color: chipTextColor ?? theme.colorScheme.onPrimary,
              ),
            ),
            backgroundColor: chipColor ?? theme.colorScheme.primary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }

  Future<void> _showMultiSelectDialog(
    BuildContext context,
    FormFieldState<List<T>> state,
  ) async {
    final result = await showDialog<List<T>>(
      context: context,
      builder: (BuildContext context) {
        return _MultiSelectDialog<T>(
          items: items,
          selectedItems: List<T>.from(selectedItems),
          displayText: displayText,
          valueGetter: valueGetter,
          dialogTitle: dialogTitle,
          searchHintText: searchHintText,
          enableSearch: enableSearch,
        );
      },
    );

    if (result != null) {
      state.didChange(result);
      onChanged(result);
    }
  }
}

class _MultiSelectDialog<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) displayText;
  final dynamic Function(T) valueGetter;
  final String dialogTitle;
  final String searchHintText;
  final bool enableSearch;

  const _MultiSelectDialog({
    Key? key,
    required this.items,
    required this.selectedItems,
    required this.displayText,
    required this.valueGetter,
    required this.dialogTitle,
    required this.searchHintText,
    required this.enableSearch,
  }) : super(key: key);

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> _selectedItems;
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedItems = List<T>.from(widget.selectedItems);
    _filteredItems = List<T>.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List<T>.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where(
              (item) => widget
                  .displayText(item)
                  .toLowerCase()
                  .contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  bool _isSelected(T item) {
    return _selectedItems.any(
      (selected) => widget.valueGetter(selected) == widget.valueGetter(item),
    );
  }

  void _toggleItem(T item) {
    setState(() {
      if (_isSelected(item)) {
        _selectedItems.removeWhere(
          (selected) =>
              widget.valueGetter(selected) == widget.valueGetter(item),
        );
      } else {
        _selectedItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.enableSearch)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: widget.searchHintText,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onChanged: _filterItems,
                ),
              ),
            Flexible(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No items found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = _isSelected(item);

                        return CheckboxListTile(
                          title: Text(
                            widget.displayText(item),
                            style: TextStyle(fontSize: 14),
                          ),
                          value: isSelected,
                          onChanged: (_) => _toggleItem(item),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          activeColor: theme.colorScheme.primary,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedItems.clear();
            });
          },
          child: Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedItems),
          child: Text('Confirm (${_selectedItems.length})'),
        ),
      ],
    );
  }
}

Widget buildSelectOption(String item, String description) {
  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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




/**GenericMultiSelectDropdown<String>(
                          label: '',
                          items: listStatusUser,
                          selectedItems: _selectedStatusList,
                          displayText: (item) => item,
                          valueGetter: (item) => item,
                          onChanged: (List<String> selectedItems) {
                            setState(() {
                              _selectedStatusList = selectedItems;
                            });
                          },
                          hintText: localization.selectedPermission,
                        ),
                        /* GenericDropdownFormField<String>(
                          label: "",
                          style: theme.textTheme.bodyMedium,
                          items: listStatusUser,
                          value: permissionsController.text.isEmpty
                              ? null
                              : permissionsController.text,
                          displayText: (status) => status,
                          valueGetter: (status) => status,
                          onChanged: (value) {
                            permissionsController.text = value ?? '';
                          },
                          hintText: localization.selectedPermission,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a permission';
                            }
                            return null;
                          },
                        ),*/
                        /* GenericDropdownFormField<PermissionEntity>(
                          label: localization.selectedPermission,
                          style: theme.textTheme.bodyMedium,
                          items: _permissionsList,
                          value: selectedPermissionId != null
                              ? _permissionsList.firstWhere(
                                  (e) => e.id == selectedPermissionId,
                                  orElse: () => PermissionEntity(
                                    id: '',
                                    code: '',
                                    description: '',
                                  ),
                                )
                              : null,
                          displayText: (permission) => permission.code,
                          valueGetter: (permission) => permission.id,
                          onChanged: (id) {
                            setState(() {
                              selectedPermissionId = id;
                            });
                            print('Selected permission ID: $id');
                          },
                          hintText: localization.selectedPermission,
                          prefixIcon: Icon(Icons.lock),
                          validator: (value) {
                            if (value == null)
                              return 'Please select a permission';
                            return null;
                          },
                        ),*/ */