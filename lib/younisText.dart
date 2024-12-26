import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class YounisText extends StatelessWidget {

  const YounisText(this.text, {super.key, this.fontSize = 24, this.color = Colors.black});
  final String text;
  final double fontSize;
  final dynamic color;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.poppins(fontSize: fontSize, color: color),);
  }
}