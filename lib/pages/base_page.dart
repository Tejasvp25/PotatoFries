import 'package:flutter/material.dart';

abstract class BasePage extends StatelessWidget {
  String get title;
  IconData get icon;
  String get providerKey;
}
