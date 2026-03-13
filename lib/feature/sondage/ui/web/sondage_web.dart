import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/ui/web/sondage_web_skeleton.dart';

class SondageWeb extends StatefulWidget {
  const SondageWeb({super.key});

  @override
  State<SondageWeb> createState() => _SondageWebState();
}

class _SondageWebState extends State<SondageWeb> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simula caricamento dati - sostituire con chiamata API reale
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostra skeleton durante il caricamento
    if (_isLoading) {
      return const SondageWebSkeleton();
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("Sondaggio web"),
    );
  }
}
