import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumBackground extends StatefulWidget {
  const PremiumBackground({super.key});

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F13), 
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned(
                top: MediaQuery.of(context).size.height * 0.1 + (sin(_controller.value * pi * 2) * 80),
                left: MediaQuery.of(context).size.width * 0.1 + (cos(_controller.value * pi * 2) * 80),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.2 + (cos(_controller.value * pi * 2) * 60),
                right: MediaQuery.of(context).size.width * 0.1 + (sin(_controller.value * pi * 2) * 60),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurpleAccent.withOpacity(0.2),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4 + (sin(_controller.value * pi) * 40),
                right: MediaQuery.of(context).size.width * 0.3 + (cos(_controller.value * pi) * 40),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withOpacity(0.15),
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ],
          );
        },
      ),
    );
  }
}