import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? color;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size, color: color),
      onPressed: onPressed,
    );
  }
}
