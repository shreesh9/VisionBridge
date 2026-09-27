/// VisionBridge — User Avatar Widget
///
/// Designed & Authored by Shreesh Nalawade (SN09092005)
/// Displays profile picture (Base64 data, Network URL, or Local File) with initial badge fallback.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
    this.radius = 22,
    this.backgroundColor,
    this.textColor,
  });

  final String? photoUrl;
  final String? displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final name = (displayName != null && displayName!.trim().isNotEmpty)
        ? displayName!.trim()
        : 'User';
    final initial = name.substring(0, 1).toUpperCase();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? const Color(0xFF4B447A) : const Color(0xFF6C5CE7));
    final fg = textColor ?? Colors.white;

    Widget? avatarImage;

    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      final str = photoUrl!.trim();
      try {
        if (str.startsWith('data:image')) {
          final base64Bytes = base64Decode(str.split(',').last);
          avatarImage = Image.memory(
            base64Bytes,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackInitial(initial, bg, fg),
          );
        } else if (str.startsWith('http://') || str.startsWith('https://')) {
          avatarImage = Image.network(
            str,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackInitial(initial, bg, fg),
          );
        } else {
          final file = File(str);
          if (file.existsSync()) {
            avatarImage = Image.file(
              file,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackInitial(initial, bg, fg),
            );
          }
        }
      } catch (_) {}
    }

    if (avatarImage != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg.withOpacity(0.2),
        child: ClipOval(child: avatarImage),
      );
    }

    return _fallbackInitial(initial, bg, fg);
  }

  Widget _fallbackInitial(String initial, Color bg, Color fg) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
