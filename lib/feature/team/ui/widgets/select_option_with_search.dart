import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

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
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedValue = value != null ? valueGetter(value as T) : null;
    final borderRadius = BorderRadius.circular(18);
    final effectiveFillColor =
        fillColor ?? colorScheme.textfieldFillColor ?? theme.cardColor;
    final effectiveStyle =
        style ??
        theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.textColor,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(fontSize: 16);
    final effectiveHintStyle =
        hintStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.descriptionColor,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(color: Colors.grey[600]);
    final compact = isDense;
    final menuItems = items.map((T item) {
      final itemValue = valueGetter(item);
      final isSelected = selectedValue != null && itemValue == selectedValue;
      return DropdownMenuItem<dynamic>(
        alignment: Alignment.centerLeft,
        value: itemValue,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.selectionColor?.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(
                    color: colorScheme.selectionColor!.withValues(alpha: 0.32),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 28 : 32,
                height: compact ? 28 : 32,
                decoration: BoxDecoration(
                  color: colorScheme.selectionColor?.withValues(
                    alpha: isSelected ? 0.18 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: compact ? 15 : 16,
                  color: colorScheme.cursorColor,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Text(
                  displayText(item),
                  style: effectiveStyle.copyWith(
                    fontSize: compact ? 13.5 : effectiveStyle.fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: compact ? 18 : 20,
                  color: colorScheme.cursorColor,
                ),
            ],
          ),
        ),
      );
    }).toList();

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
          initialValue: selectedValue,
          items: menuItems,
          selectedItemBuilder: (context) => items.map((T item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: compact ? 28 : 32,
                    height: compact ? 28 : 32,
                    decoration: BoxDecoration(
                      color: colorScheme.selectionColor?.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      size: compact ? 15 : 16,
                      color: colorScheme.cursorColor,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Text(
                      displayText(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: effectiveStyle.copyWith(
                        fontSize: compact ? 13.5 : effectiveStyle.fontSize,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: isExpanded,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(22),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: effectiveHintStyle,
            prefixIcon: prefixIcon == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(
                      left: compact ? 10 : 12,
                      right: compact ? 8 : 10,
                    ),
                    child: _DropdownAffixShell(
                      compact: compact,
                      child: prefixIcon!,
                    ),
                  ),
            prefixIconConstraints: BoxConstraints(
              minWidth: compact ? 40 : 52,
              minHeight: compact ? 40 : 52,
            ),
            suffixIcon: suffixIcon,
            contentPadding:
                contentPadding ??
                EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 12 : 16,
                ),
            border:
                border ??
                OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: colorScheme.bottomOutline!),
                ),
            enabledBorder:
                border ??
                OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(
                    color: colorScheme.bottomOutline!,
                    width: 1.2,
                  ),
                ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                color: colorScheme.selectionColor!,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: colorScheme.error, width: 1.4),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            filled: true,
            fillColor: effectiveFillColor,
            isDense: isDense,
          ),
          dropdownColor:
              dropdownColor ?? colorScheme.bgNavbarSurface ?? theme.cardColor,
          elevation: elevation ?? 12,
          iconSize: iconSize ?? (compact ? 20 : 24),
          icon: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: EdgeInsets.all(compact ? 4 : 6),
            decoration: BoxDecoration(
              color: colorScheme.selectionColor?.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colorScheme.selectionColor!.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: compact ? 16 : 18,
              color: iconColor ?? colorScheme.cursorColor ?? Colors.grey[600],
            ),
          ),
          iconEnabledColor: Colors.transparent,
          iconDisabledColor: Colors.grey[400],
          style: effectiveStyle,
          enableFeedback: enableFeedback,
        ),
      ],
    );
  }
}

class _DropdownAffixShell extends StatelessWidget {
  const _DropdownAffixShell({required this.child, required this.compact});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: compact ? 30 : 36,
      height: compact ? 30 : 36,
      decoration: BoxDecoration(
        color: colorScheme.selectionColor?.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(
          color: colorScheme.selectionColor!.withValues(alpha: 0.18),
        ),
      ),
      child: Center(child: child),
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
    super.key,
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
  });

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
    super.key,
    required this.items,
    required this.selectedItems,
    required this.displayText,
    required this.valueGetter,
    required this.dialogTitle,
    required this.searchHintText,
    required this.enableSearch,
  });

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
          child: Text(AppLocalizations.of(context)!.clearAll),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedItems),
          child: Text(
            '${AppLocalizations.of(context)!.confirm} (${_selectedItems.length})',
          ),
        ),
      ],
    );
  }
}
