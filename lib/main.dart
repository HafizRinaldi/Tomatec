import 'package:flutter/material.dart';
import 'package:tomatect/riwayat.dart';
import 'package:tomatect/utama.dart';

Future<void> main() async {
  runApp(
    MaterialApp(
      initialRoute: '/',
      routes: {'/': (context) => const HomePage()},
    ),
  );
}
