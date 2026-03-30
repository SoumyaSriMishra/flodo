import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class DraftProvider extends ChangeNotifier {
  String draftTitle = '';
  String draftDescription = '';
  DateTime? draftDueDate;
  String draftStatus = 'To-Do';
  String? draftBlockedById;
  bool draftIsRecurring = false;
  String? draftRecurrenceInterval;

  bool get hasDraft => draftTitle.isNotEmpty || draftDescription.isNotEmpty || draftDueDate != null;

  Future<void> loadDraft() async {
    final box = Hive.box('draft');
    draftTitle = box.get('title', defaultValue: '') as String;
    draftDescription = box.get('description', defaultValue: '') as String;
    final ms = box.get('dueDate');
    draftDueDate = ms != null ? DateTime.fromMillisecondsSinceEpoch(ms as int) : null;
    draftStatus = box.get('status', defaultValue: 'To-Do') as String;
    draftBlockedById = box.get('blockedById') as String?;
    draftIsRecurring = box.get('isRecurring', defaultValue: false) as bool;
    draftRecurrenceInterval = box.get('recurrenceInterval') as String?;
    notifyListeners();
  }

  Future<void> saveDraft({
    required String title,
    required String description,
    DateTime? dueDate,
    required String status,
    String? blockedById,
    required bool isRecurring,
    String? recurrenceInterval,
  }) async {
    draftTitle = title;
    draftDescription = description;
    draftDueDate = dueDate;
    draftStatus = status;
    draftBlockedById = blockedById;
    draftIsRecurring = isRecurring;
    draftRecurrenceInterval = recurrenceInterval;
    final box = Hive.box('draft');
    await Future.wait([
      box.put('title', title),
      box.put('description', description),
      box.put('dueDate', dueDate?.millisecondsSinceEpoch),
      box.put('status', status),
      box.put('blockedById', blockedById),
      box.put('isRecurring', isRecurring),
      box.put('recurrenceInterval', recurrenceInterval),
    ]);
    // Intentionally no notifyListeners(): called on every keystroke (debounced in UI)
  }

  Future<void> clearDraft() async {
    await Hive.box('draft').clear();
    draftTitle = '';
    draftDescription = '';
    draftDueDate = null;
    draftStatus = 'To-Do';
    draftBlockedById = null;
    draftIsRecurring = false;
    draftRecurrenceInterval = null;
    notifyListeners();
  }
}
