import 'package:flutter/material.dart';

import 'historial_screen.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Parejas'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 90,
                color: Colors.teal,
              ),
              const SizedBox(height: 20),
              const Text(
                'Bienvenido a Gastos Parejas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                'Organiza y consulta tus gastos de manera sencilla.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistorialScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Ver historial de gastos'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
