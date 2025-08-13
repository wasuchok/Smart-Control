import 'package:flutter/material.dart';

class LampTile extends StatelessWidget {
  final bool isOn;
  final Color lampOnColor;
  final Color lampOffColor;
  final VoidCallback onTap;
  final String zone;

  const LampTile({
    super.key,
    required this.isOn,
    required this.lampOnColor,
    required this.lampOffColor,
    required this.onTap,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    final whiteBg = Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isOn ? lampOnColor : whiteBg,
        boxShadow: [
          BoxShadow(
            color: isOn
                ? lampOnColor.withOpacity(0.4)
                : Colors.grey[300]!.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOn
                            ? Colors.white24
                            : lampOffColor.withOpacity(0.08),
                      ),
                      child: Icon(
                        Icons.lightbulb_outlined,
                        color: isOn ? Colors.white : lampOffColor,
                        size: 26,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$zone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOn ? Colors.white : Colors.grey[700]!,
                    fontSize: 14,
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 4),

                SizedBox(
                  height: 24,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isOn ? Colors.white24 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOn ? 'ACTIVE' : 'OFF',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isOn ? Colors.white : Colors.grey[600]!,
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
