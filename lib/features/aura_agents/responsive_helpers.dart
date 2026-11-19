import 'package:flutter/material.dart';

/// Mobile layout is used below the same breakpoint as the main dashboard
/// (NavigationRail on desktop, drawer on mobile). Desktop layout is untouched.
bool isMobileLayout(BuildContext context) => MediaQuery.of(context).size.width < 800;

/// Desktop: normal Row. Mobile: 2-column grid of the (Expanded) metric cards.
class ResponsiveMetricRow extends StatelessWidget {
  const ResponsiveMetricRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!isMobileLayout(context)) return Row(children: children);
    final cards = <Widget>[
      for (final w in children)
        if (w is Expanded) w.child,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final cardWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

/// Desktop: normal Row. Mobile: search field on its own line, the remaining
/// filters (dropdowns / refresh button) below it sharing the width.
class ResponsiveFilterBar extends StatelessWidget {
  const ResponsiveFilterBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!isMobileLayout(context)) return Row(children: children);
    final real = children.where((w) => w is! SizedBox).toList();
    if (real.isEmpty) return const SizedBox.shrink();
    final first = real.first;
    final search = first is Expanded ? first.child : first;
    final rest = real.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        search,
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < rest.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                if (rest[i] is IconButton) rest[i] else Expanded(child: rest[i]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Shared KPI card. Desktop look is the same as before; on mobile it is compact
/// so two cards fit per row without clipping.
Widget buildMetricCardShared(
  BuildContext context, {
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  double radius = 12,
  Color? borderColor,
  double iconSize = 24,
  double valueSize = 20,
  double titleGap = 2,
  bool isAlert = false,
}) {
  final m = isMobileLayout(context);
  final valueText = Text(
    value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: Colors.white,
      fontSize: m ? valueSize - 3 : valueSize,
      fontWeight: FontWeight.bold,
    ),
  );
  final valueWidget = m
      ? FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: valueText)
      : valueText;

  return Expanded(
    child: Container(
      padding: EdgeInsets.all(m ? 10 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isAlert ? const Color(0xFFFFB703) : (borderColor ?? color.withValues(alpha: 0.2)),
          width: isAlert ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(m ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: m ? iconSize - 6 : iconSize),
          ),
          SizedBox(width: m ? 8 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white54, fontSize: m ? 11 : 12),
                ),
                SizedBox(height: titleGap),
                if (isAlert)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      valueWidget,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB703).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTION REQUIRED',
                          style: TextStyle(
                            color: Color(0xFFFFB703),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  valueWidget,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}