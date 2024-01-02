import 'package:flutter/material.dart';

enum Categories {
  vegetables,
  carbs,
  sweets,
  spices,
  dairy,
  fruit,
  meat,
  milk,
  convenience,
  hygiene,
  other
}

class Category {
  const Category(
    this.title,
    this.color,
  );

  final String title;
  final Color color;
}
