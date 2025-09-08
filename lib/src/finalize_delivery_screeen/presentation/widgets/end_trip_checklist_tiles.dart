import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/entity/end_checklist_entity.dart';

class EndTripChecklistTile extends StatefulWidget {
  final EndChecklistEntity checklist;
  final Function(bool?) onChanged;
  final bool isChecked;

  const EndTripChecklistTile({
    super.key,
    required this.checklist,
    required this.onChanged,
    required this.isChecked,
  });

  @override
  State<EndTripChecklistTile> createState() => _EndTripChecklistTileState();
}

class _EndTripChecklistTileState extends State<EndTripChecklistTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          leading: Checkbox(
            value: widget.isChecked,
            onChanged: (value) {
              widget.onChanged(value);
            },
            activeColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            widget.checklist.objectName ?? 'No Name',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration:
                      widget.isChecked ? TextDecoration.lineThrough : null,
                  color: widget.isChecked
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5)
                      : Theme.of(context).colorScheme.onSurface,
                ),
          ),

          // Expandable description
          children: [
            if (widget.checklist.description != null &&
                widget.checklist.description!.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(left: 20, right: 16, bottom: 16),
                child: Text(
                  widget.checklist.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
