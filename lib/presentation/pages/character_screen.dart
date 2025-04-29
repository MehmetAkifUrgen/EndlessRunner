import 'package:flutter/material.dart';

// TODO: Karakter seçim ekranının içeriğini buraya ekleyin.
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Character'),
        backgroundColor: Colors.teal, // HomeScreen'deki butona uygun bir renk
      ),
      body: const Center(
        child: Text(
          'Character Selection Screen - Coming Soon!',
          style: TextStyle(color: Colors.black), // Scaffold'un varsayılan arkaplanı beyaz olabilir
        ),
      ),
    );
  }
}
