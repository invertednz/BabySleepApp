import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6D7F2), Color(0xFFC8A2C8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'BabySteps',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Consumer<BabyProvider>(
            builder: (context, babyProvider, _) {
              final babies = babyProvider.babies;
              final selected = babyProvider.selectedBaby;
              return DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    value: selected?.id,
                    hint: const Text('Select baby', style: TextStyle(color: Colors.white)),
                    items: babies
                        .map(
                          (b) => DropdownMenuItem<String>(
                            value: b.id,
                            child: Text(b.name, style: const TextStyle(color: Colors.black)),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) {
                        babyProvider.selectBaby(id);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
