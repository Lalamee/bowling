import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/order_item.dart';

class DetailRow extends StatefulWidget {
  final OrderItem item;

  const DetailRow({Key? key, required this.item}) : super(key: key);

  @override
  State<DetailRow> createState() => _DetailRowState();
}

class _DetailRowState extends State<DetailRow> {
  late final TextEditingController title;
  late final TextEditingController qty;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.item.title);
    qty = TextEditingController(text: widget.item.qty > 0 ? '${widget.item.qty}' : '');
  }

  @override
  void dispose() {
    title.dispose();
    qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _inputContainer(
            child: TextField(
              controller: title,
              decoration: const InputDecoration(border: InputBorder.none),
              style: const TextStyle(color: Color(0xFF23262F), fontSize: 14),
              onChanged: (v) => widget.item.title = v,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: _inputContainer(
            child: TextField(
              controller: qty,
              decoration: const InputDecoration(
                border: InputBorder.none,
                suffixText: 'шт',
                suffixStyle: TextStyle(color: Color(0xFF23262F), fontSize: 14),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Color(0xFF23262F), fontSize: 14),
              onChanged: (v) {
                final parsed = int.tryParse(v) ?? 0;
                widget.item.qty = parsed;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputContainer({required Widget child}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
