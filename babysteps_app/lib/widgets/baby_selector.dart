import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';

class BabySelector extends StatelessWidget {
  final String name;
  final String age;
  final String? imageUrl;
  final VoidCallback onTap;

  const BabySelector({
    required this.name,
    required this.age,
    required this.onTap,
    this.imageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Baby avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(FeatherIcons.user, size: 16, color: Color(0xFFA67EB7)),
                        );
                  },
                )
                  : Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(FeatherIcons.user, size: 16, color: Color(0xFFA67EB7)),
                    ),
              ),
              const SizedBox(width: 12),
              // Baby name and age
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    age,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // No dropdown icon as per request
        ],
      ),
    );
  }
}
