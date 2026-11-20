import 'package:flutter/material.dart';

/// الزخرفة اللي بتترسم في خلفية البطاقة.
enum Motif { crescent, stars, confetti, waves, hearts, frame, dots }

class CardStyle {
  final String name;
  final List<Color> colors;
  final Color text;
  final Color accent;
  final Motif motif;

  const CardStyle({
    required this.name,
    required this.colors,
    required this.text,
    required this.accent,
    required this.motif,
  });
}

const cardStyles = <CardStyle>[
  CardStyle(
    name: 'ليل رمضان',
    colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)],
    text: Colors.white,
    accent: Color(0xFFFCD34D),
    motif: Motif.crescent,
  ),
  CardStyle(
    name: 'ذهبي',
    colors: [Color(0xFF3B2414), Color(0xFF92400E)],
    text: Color(0xFFFFF7E0),
    accent: Color(0xFFFBBF24),
    motif: Motif.stars,
  ),
  CardStyle(
    name: 'أخضر ملكي',
    colors: [Color(0xFF064E3B), Color(0xFF047857)],
    text: Colors.white,
    accent: Color(0xFFFCD34D),
    motif: Motif.frame,
  ),
  CardStyle(
    name: 'وردي',
    colors: [Color(0xFFDB2777), Color(0xFFF472B6)],
    text: Colors.white,
    accent: Colors.white,
    motif: Motif.hearts,
  ),
  CardStyle(
    name: 'سماوي',
    colors: [Color(0xFF0284C7), Color(0xFF6366F1)],
    text: Colors.white,
    accent: Color(0xFFFDE68A),
    motif: Motif.confetti,
  ),
  CardStyle(
    name: 'بحري',
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    text: Colors.white,
    accent: Colors.white,
    motif: Motif.waves,
  ),
  CardStyle(
    name: 'كريمي',
    colors: [Color(0xFFFFF7ED), Color(0xFFFDE68A)],
    text: Color(0xFF78350F),
    accent: Color(0xFFB45309),
    motif: Motif.frame,
  ),
  CardStyle(
    name: 'ليلكي',
    colors: [Color(0xFF6D28D9), Color(0xFFC084FC)],
    text: Colors.white,
    accent: Color(0xFFFDF4FF),
    motif: Motif.stars,
  ),
  CardStyle(
    name: 'غروب',
    colors: [Color(0xFFF97316), Color(0xFFDB2777)],
    text: Colors.white,
    accent: Color(0xFFFEF3C7),
    motif: Motif.confetti,
  ),
  CardStyle(
    name: 'أبيض أنيق',
    colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
    text: Color(0xFF0F172A),
    accent: Color(0xFF0F766E),
    motif: Motif.dots,
  ),
];
