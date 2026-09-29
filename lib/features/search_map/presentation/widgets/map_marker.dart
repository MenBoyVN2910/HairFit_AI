import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/search_provider.dart';

/// Widget marker hiển thị trên OpenStreetMap cho thợ cắt tóc (Task 3.5)
class BarberMapMarker extends StatelessWidget {
  final BarberWithDistance item;
  final VoidCallback onTap;

  const BarberMapMarker({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMatch = item.isMatchingHairstyle;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Khung pin
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isMatch ? AppColors.accent : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isMatch ? AppColors.accent : Colors.black)
                      .withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
            ),
            child: Icon(
              isMatch ? Icons.auto_awesome : Icons.content_cut_rounded,
              color: isMatch ? Colors.white : AppColors.accent,
              size: isMatch ? 20 : 18,
            ),
          ),
          // Mũi nhọn pin
          ClipPath(
            clipper: _TriangleClipper(),
            child: Container(
              width: 10,
              height: 6,
              color: isMatch ? AppColors.accent : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Marker hiển thị vị trí GPS của người dùng
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withValues(alpha: 0.2),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade600,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
