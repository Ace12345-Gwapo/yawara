// ============================================================
// lib/widgets/remarks_handler.dart
// FIX: Simpler, cleaner remarks placeholder text
// ============================================================

import 'package:flutter/material.dart';

class RemarksHandler {
  static Widget buildRemarksField(TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Remarks',
        hintText: 'Optional — e.g. OB, Meeting, Room Change',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note_alt_outlined),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}