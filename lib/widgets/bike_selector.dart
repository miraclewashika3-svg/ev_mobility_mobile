import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../theme/app_colors.dart';

// A horizontal row of selectable chips, one per bike -- rendered only when
// a rider has more than one, so the common single-bike case stays exactly
// as uncluttered as it always was. Shared between BikeProfileScreen
// (browsing a bike's profile/history) and LogSwapScreen (picking which
// bike a swap counts against), so a rider with a growing fleet gets the
// same picker wherever the app needs to know "which bike."
class BikeSelector extends StatelessWidget {
  final List<Bike> bikes;
  final int selectedBikeId;
  final ValueChanged<Bike> onSelected;

  const BikeSelector({
    super.key,
    required this.bikes,
    required this.selectedBikeId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (bikes.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bikes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bike = bikes[index];
          final isSelected = bike.id == selectedBikeId;

          return ChoiceChip(
            label: Text(bike.model),
            selected: isSelected,
            onSelected: (_) => onSelected(bike),
            showCheckmark: false,
            backgroundColor: context.colors.surface,
            selectedColor: context.colors.accentSurface,
            side: BorderSide(
              color: isSelected ? context.colors.accent : context.colors.border,
            ),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? context.colors.accent : context.colors.inkMuted,
            ),
          );
        },
      ),
    );
  }
}
