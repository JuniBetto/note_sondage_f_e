import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// La pagina "Oops!" mostrata all'utente per un errore fatale
/// che non è stato gestito.
class ErrorPage extends StatelessWidget {
  final String? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                "Oops! Qualcosa è andato storto.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Abbiamo notificato il nostro team. Per favore, prova a riavviare l'app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // TODO: Aggiungere logica per riavviare l'app o
                  // tornare alla home. Per ora, chiudiamo la pagina.
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Torna Indietro"),
              ),
              // Mostra i dettagli dell'errore solo in modalità DEBUG
              if (kDebugMode && error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ExpansionTile(
                    title: const Text("Dettagli Errore (Debug)"),
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
