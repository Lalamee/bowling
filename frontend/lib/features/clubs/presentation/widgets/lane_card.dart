import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/layout/common_ui.dart';

class LaneCard extends StatefulWidget {
  final String title;
  final Widget? child;
  final bool initiallyOpen;

  const LaneCard({
    Key? key,
    required this.title,
    this.child,
    this.initiallyOpen = false,
  }) : super(key: key);

  @override
  State<LaneCard> createState() => _LaneCardState();
}

class _LaneCardState extends State<LaneCard> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
  }

  @override
  Widget build(BuildContext context) {
    return CommonUI.card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: const Color(0xFFEDEDED), width: 1),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const Spacer(),
                  Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.darkGray),
                ],
              ),
            ),
          ),
          if (_open && widget.child != null)
            Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 16), child: widget.child!),
        ],
      ),
    );
  }
}
