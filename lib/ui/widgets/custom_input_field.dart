import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart'; // Necessario per il filtro dei numeri

const _kDefaultBorderRadius = 12.0;

// Cache del Padding di default
const _kContentPadding = EdgeInsets.symmetric(vertical: 15, horizontal: 20);

// Cache del formatter numerico
final _kDigitsOnlyFormatter = [FilteringTextInputFormatter.digitsOnly];

// =========================================================

class CustomInputField extends StatefulWidget {
  final String hintText;
  final IconData? prefixIcon; // Icona opzionale a sinistra
  final TextEditingController controller;
  final bool isPassword;
  final bool isSearch; // Se true, mostra l'icona di ricerca a destra
  final bool isNumber;
  final int? minLines;
  final int? maxLines;
  final String? Function(String?)? validator; // Funzione di validazione
  final void Function()? onSearchPressed; // Callback per il pulsante di ricerca

  const CustomInputField({
    super.key,
    required this.hintText,
    required this.controller,
    this.prefixIcon,
    this.isPassword = false, // Default: false
    this.isSearch = false, // Default: false
    this.isNumber = false, // Default: false
    this.validator,
    this.minLines,
    this.maxLines = 1,
    this.onSearchPressed,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _isObscured = true; // Stato per nascondere la password

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      controller: widget.controller,
      // Logica per nascondere il testo se è una password
      obscureText: widget.isPassword ? _isObscured : false,
      // Logica per la tastiera: Numerica o Testo
      keyboardType: widget.isNumber ? TextInputType.number : TextInputType.text,

      // Se è number, accetta solo cifre (usando la costante cached)
      inputFormatters: widget.isNumber ? _kDigitsOnlyFormatter : [],

      // Funzione di validazione (gestisce bordo rosso e messaggio)
      validator: widget.validator,

      decoration: InputDecoration(
        hintText: widget.hintText,
        // Usa la costante cached
        contentPadding: _kContentPadding,

        // Mostra l'icona a sinistra solo se è stata passata
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: colorScheme.bgIcons)
            : null,

        // Se è password, mostra l'icona per vedere/nascondere
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: colorScheme.bgIcons,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : widget.isSearch
            ? IconButton(
                icon: Icon(Icons.search, color: colorScheme.bgIcons),
                onPressed: widget.onSearchPressed,
              )
            : null,

        // =========================================================
        // UTILIZZO DELLE COSTANTI CACHED PER I BORDER
        // =========================================================
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.bottomOutline!),
        ), // Usa costante
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.bottomOutline!),
        ), // Usa costante
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.selectionColor!, width: 2),
        ), // Usa costante
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ), // Usa costante
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kDefaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 2.0),
        ), // Usa costante
        // =========================================================
      ),
    );
  }
}

String? emailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }

  // Rimuovi spazi all'inizio e alla fine
  final trimmedValue = value.trim();

  // Controlla se contiene "@"
  if (!trimmedValue.contains('@')) {
    return 'Email must contain @ symbol';
  }

  // Controlla che non ci siano spazi
  if (trimmedValue.contains(' ')) {
    return 'Email cannot contain spaces';
  }

  // Controlla la posizione di "@"
  final atIndex = trimmedValue.indexOf('@');
  if (atIndex == 0) {
    return 'Email must have characters before @';
  }
  if (atIndex == trimmedValue.length - 1) {
    return 'Email must have characters after @';
  }

  // Controlla che ci sia almeno un punto dopo "@"
  final domainPart = trimmedValue.substring(atIndex + 1);
  if (!domainPart.contains('.')) {
    return 'Email domain must contain a dot';
  }

  // Controlla che il dominio non termini con un punto
  if (domainPart.endsWith('.')) {
    return 'Email domain cannot end with a dot';
  }

  // Regex più accurata
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$',
  );

  if (!emailRegex.hasMatch(trimmedValue)) {
    return 'Please enter a valid email address';
  }

  return null;
}
