import 'dart:ui';
import 'package:flutter/material.dart';

void showPremiumModal(BuildContext context, {required Widget child}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, 
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, 
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Kunci agar tidak full screen
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                child, // Dihapus Flexible-nya
              ],
            ),
          ),
        ),
      );
    },
  );
}