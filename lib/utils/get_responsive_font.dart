import 'package:flutter/material.dart';

getadaptiveTextSize(BuildContext context, dynamic value) {
  return (value / 720) * MediaQuery.of(context).size.height;
}

