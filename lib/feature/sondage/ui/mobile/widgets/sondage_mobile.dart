import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/sondage_mobile_skeleton.dart';

class SondageMobile extends StatefulWidget {
  const SondageMobile({super.key});

  @override
  State<SondageMobile> createState() => _SondageMobileState();
}

class _SondageMobileState extends State<SondageMobile> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simula il caricamento dei dati
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SondageMobileSkeleton();
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("Sondaggio Mobile"),
    );
  }
}
