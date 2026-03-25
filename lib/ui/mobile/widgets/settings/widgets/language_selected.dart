import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LanguageSelector extends StatefulWidget {
  final List<Map<String, dynamic>> languages;
  final List<String> selectedLanguages;
  final Function(List<String>) onSelectionChanged;
  final bool isMobile;

  const LanguageSelector({
    super.key,
    required this.languages,
    required this.selectedLanguages,
    required this.onSelectionChanged,
    this.isMobile = true,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late List<String> _selectedLanguages;

  @override
  void initState() {
    super.initState();
    _selectedLanguages = List.from(widget.selectedLanguages);
  }

  @override
  void didUpdateWidget(LanguageSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLanguages != oldWidget.selectedLanguages) {
      setState(() {
        _selectedLanguages = List.from(widget.selectedLanguages);
      });
    }
  }

  void _toggleLanguage(String languageCode) {
    setState(() {
      if (_selectedLanguages.contains(languageCode)) {
        _selectedLanguages.remove(languageCode);
      } else {
        _selectedLanguages
            .clear(); // Clear previous selection for single selection behavior
        _selectedLanguages.add(languageCode);
      }
      widget.onSelectionChanged(_selectedLanguages);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return widget.isMobile
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Language", style: textTheme.headlineMedium),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.languages.map((language) {
                    final isSelected = _selectedLanguages.contains(
                      language['code'],
                    );
                    return _buildLanguageItem(language, isSelected, null);
                  }).toList(),
                ),
              ),
            ],
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.languages.map((language) {
              final isSelected = _selectedLanguages.contains(language['code']);
              return _buildLanguageItem(language, isSelected, 240);
            }).toList(),
          );
  }

  Widget _buildLanguageItem(
    Map<String, dynamic> language,
    bool isSelected,
    double? width,
  ) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) => _toggleLanguage(language['code']),
          activeColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        title: Text(
          language['name'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SvgPicture.asset(
            language['flagPath'],
            width: 32,
            height: 24,
            fit: BoxFit.cover,
            placeholderBuilder: (context) {
              print('Error loading flag image for ${language['name']}');
              return Container(
                width: 32,
                height: 24,
                color: Colors.grey.shade300,
                child: const Icon(Icons.flag, size: 16, color: Colors.grey),
              );
            },
          ) /*Image.asset(
            language['flagPath'],
            width: 32,
            height: 24,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading flag image: $error');
              return Container(
                width: 32,
                height: 24,
                color: Colors.grey.shade300,
                child: const Icon(Icons.flag, size: 16, color: Colors.grey),
              );
            },
          ),*/,
        ),
        onTap: () => _toggleLanguage(language['code']),
      ),
    );
  }
}
