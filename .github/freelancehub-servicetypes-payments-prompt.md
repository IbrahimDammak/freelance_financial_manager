# FEATURE 6 — GENERALIZED SERVICE TYPES & PAYMENT TRACKING
## Dynamic Service Categories · Payment Update Flow · Payment History Log

## SCOPE
This prompt fixes two issues and adds one supporting feature:

1. **Issue 1 — Hardcoded project types:** `'website'` and `'graphic'` are burned into models, UI, and logic. Replace with a fully user-defined, extensible list of service categories stored in `AppSettings`.
2. **Issue 2 — No way to record payments:** Once a project is created, `remaining` is frozen. The user has no UI to log that a client paid them. Fix by adding a payment recording flow with a full payment history log.
3. **Supporting feature — Payment history model:** Each payment event needs to be stored with date, amount, and optional note so the user has a clear audit trail.

**Files to create or modify are listed per section. All other files remain unchanged.**

---

# PART 1 — GENERALIZED SERVICE TYPES

## 1A. Add `PaymentRecord` Model — `lib/models/payment_record.dart`

Create this file before modifying anything else. It is needed by the updated `Project` model.

```dart
import 'package:hive/hive.dart';
part 'payment_record.g.dart';

@HiveType(typeId: 4)
class PaymentRecord extends HiveObject {
  @HiveField(0) late String id;       // UUID
  @HiveField(1) late String date;     // 'yyyy-MM-dd'
  @HiveField(2) late double amount;   // amount received in this payment
  @HiveField(3) late String note;     // optional note e.g. "Bank transfer", "Cash"
}
```

> Register adapter in `main.dart`: `Hive.registerAdapter(PaymentRecordAdapter());`
> TypeId 4 — never reuse.

---

## 1B. Update `lib/models/app_settings.dart`

Add a user-managed list of service category names. **Append only — do not change existing field indices.**

```dart
// Append after the last existing @HiveField:
@HiveField(26) List<String> serviceCategories = const [
  'Web Development',
  'Graphic Design',
  'UI/UX Design',
  'Mobile App',
  'SEO',
  'Branding',
  'Copywriting',
  'Video Editing',
];
// This is the global pool of service types the user can pick from.
// The user can add custom categories at any time.
// Individual projects still store their own selected services list (List<String>).
```

---

## 1C. Update `lib/models/project.dart`

Replace `@HiveField(3) late String type` (the old hardcoded `'website'|'graphic'` field) with a free-form `category` string. **All other field indices remain unchanged.**

```dart
// REPLACE:
@HiveField(3) late String type;   // OLD — remove this

// WITH:
@HiveField(3) late String category;  // Free-form category name from AppSettings.serviceCategories
                                      // e.g. 'Web Development', 'Branding', 'Custom Video'
                                      // No validation — any non-empty string is valid.
```

> **Migration note:** All existing code that reads `project.type` must be updated to read `project.category`. Search the entire codebase for `.type` on `Project` objects and replace with `.category`. Do NOT rename the Hive field index — keep `@HiveField(3)`, just change the Dart property name.

Remove the `type` property from `Project` entirely. The `category` field is its complete replacement.

---

## 1D. Update `lib/models/client.dart`

Replace `@HiveField(5) late String type` (the old `'website'|'graphic'` field) with a `primaryCategory` string. **All other field indices remain unchanged.**

```dart
// REPLACE:
@HiveField(5) late String type;         // OLD — remove this

// WITH:
@HiveField(5) late String primaryCategory;  // The client's main service type
                                             // e.g. 'Web Development', 'Branding'
                                             // User selects from AppSettings.serviceCategories
                                             // or types a custom one
```

> Search entire codebase for `client.type` and replace with `client.primaryCategory`.

---

## 1E. Update `lib/models/project.dart` — Add Payment History

Append a payment history list to the `Project` model. **Append only.**

```dart
// Add after @HiveField(17):
@HiveField(18) List<PaymentRecord> payments = [];
// Chronological log of all payments received for this project.
// When a payment is recorded, DataProvider MUST:
//   1. Add the PaymentRecord to this list
//   2. Subtract payment.amount from project.remaining
//   3. Add payment.amount to project.upfront
//   4. Clamp project.remaining to >= 0.0 (never go negative)
//   5. Save to Hive
//   6. notifyListeners()
```

Import `PaymentRecord` at the top of `project.dart`:
```dart
import 'payment_record.dart';
```

---

## 1F. Update `lib/providers/settings_provider.dart`

Add service category management methods:

```dart
// ── GETTERS ───────────────────────────────────────────────────────────────
List<String> get serviceCategories =>
    List.unmodifiable(_settings.serviceCategories);

// ── MUTATIONS ─────────────────────────────────────────────────────────────

/// Add a new custom category. Trims whitespace, ignores duplicates (case-insensitive).
Future<void> addServiceCategory(String name) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;
  final existing = _settings.serviceCategories
      .map((s) => s.toLowerCase())
      .toList();
  if (existing.contains(trimmed.toLowerCase())) return;
  _settings.serviceCategories = [..._settings.serviceCategories, trimmed];
  await _settings.save();
  notifyListeners();
}

/// Remove a category by name. Prevents removing the last category.
Future<void> removeServiceCategory(String name) async {
  if (_settings.serviceCategories.length <= 1) return;
  _settings.serviceCategories =
      _settings.serviceCategories.where((s) => s != name).toList();
  await _settings.save();
  notifyListeners();
}

/// Rename an existing category. Updates the name in-place, preserving order.
Future<void> renameServiceCategory(String oldName, String newName) async {
  final trimmed = newName.trim();
  if (trimmed.isEmpty) return;
  _settings.serviceCategories = _settings.serviceCategories
      .map((s) => s == oldName ? trimmed : s)
      .toList();
  await _settings.save();
  notifyListeners();
}
```

---

## 1G. Update `lib/providers/data_provider.dart`

Add payment recording method:

```dart
/// Record a payment against a project.
/// Adds to payment history, updates upfront/remaining, saves to Hive.
/// Fires payment-complete notification if remaining reaches 0.
Future<void> recordPayment({
  required String clientId,
  required String projectId,
  required double amount,
  required String date,
  required String note,
}) async {
  try {
    final client = findClient(clientId);
    if (client == null) return;
    final project = client.projects.firstWhere((p) => p.id == projectId);

    final payment = PaymentRecord()
      ..id = const Uuid().v4()
      ..date = date
      ..amount = amount
      ..note = note;

    final wasOwing = project.remaining > 0;

    project.payments.add(payment);
    project.upfront  += amount;
    project.remaining = (project.remaining - amount).clamp(0.0, double.infinity);

    await project.save();
    notifyListeners();

    // Fire payment-complete notification if balance just cleared
    if (wasOwing && project.remaining == 0) {
      await NotificationScheduler().notifyPaymentComplete(
        projectName: project.name,
        clientName:  client.name,
        amount:      project.upfront,
        currency:    _settingsProvider.settings.currency,
      );
    }

    await _syncNotifications();
  } catch (e) {
    lastError = 'Failed to record payment: $e';
    notifyListeners();
  }
}
```

---

## 1H. Create `lib/sheets/record_payment_sheet.dart`

A bottom sheet for recording a payment against a specific project.

### Parameters
```dart
class RecordPaymentSheet extends StatefulWidget {
  final String clientId;
  final String projectId;
  final String projectName;
  final double currentRemaining;
  final String currency;
  // ...
}
```

### Layout

```
┌─────────────────────────────────────────┐
│  ▬▬▬  (drag handle)                     │
│  Record Payment          ✕              │
├─────────────────────────────────────────┤
│                                         │
│  Currently owed                         │  ← muted label
│  700.000 DT                             │  ← large, kYellow if >0, kGreen if 0
│                                         │
│  Amount Received *       [_________]    │  ← number field
│                                         │
│  [Pay in full]                          │  ← chip button — fills amount field
│                                         │
│  Date *                  [_________]    │  ← date picker, default today
│                                         │
│  Note (optional)         [_________]    │  ← text field
│  e.g. Bank transfer, Cash, Cheque       │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │  After this payment:             │   │  ← live preview card
│  │  Remaining: 200.000 DT           │   │
│  └──────────────────────────────────┘   │
│                                         │
│  [       Record Payment       ]         │  ← kBlack primary button
│                                         │
└─────────────────────────────────────────┘
```

### Behavior details

**"Pay in full" chip:**
```dart
// Small outlined chip button below the amount field:
ActionChip(
  label: Text('Pay in full'),
  onPressed: () => _amountController.text = currentRemaining.toStringAsFixed(3),
)
// Sets the amount field to the exact remaining balance.
```

**Live preview card:**
- Shows in real time as the user types in the amount field
- `remaining - enteredAmount` clamped to 0
- Color: `kGreen` if result is 0, `kYellow` if result > 0, `kRed` if amount > remaining (overpayment warning)
- If overpayment: show warning text "Amount exceeds remaining balance. Extra will be recorded as advance payment."

**Validation:**
- Amount must be > 0
- Amount field must be a valid number
- Date must not be empty

**On submit:**
```dart
await dataProvider.recordPayment(
  clientId:  widget.clientId,
  projectId: widget.projectId,
  amount:    double.parse(_amountController.text),
  date:      _selectedDate,
  note:      _noteController.text.trim(),
);
Navigator.pop(context);
```

---

## 1I. Update `lib/screens/project_detail_screen.dart`

### Add "Record Payment" button to the Financials Card

In the Financials section, after the 2×2 grid of stat cards, add:

```dart
// Only show if project.remaining > 0
if (project.remaining > 0)
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: OutlinedButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RecordPaymentSheet(
          clientId:          widget.clientId,
          projectId:         widget.projectId,
          projectName:       project.name,
          currentRemaining:  project.remaining,
          currency:          settingsProvider.settings.currency,
        ),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Record Payment'),
      style: OutlinedButton.styleFrom(
        foregroundColor:  kGreen,
        side:             BorderSide(color: kGreen.withOpacity(0.4)),
        shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize:      const Size(double.infinity, 44),
      ),
    ),
  ),
```

### Add Payment History section

Below the Work Sessions card, add a new **Payment History** card. Only shown if `project.payments.isNotEmpty`:

```dart
if (project.payments.isNotEmpty)
  Container(
    decoration: kCardDecoration(),
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('PAYMENT HISTORY'),
        const SizedBox(height: 8),
        // List payments in reverse chronological order (newest first)
        ...project.payments.reversed.map((p) => _PaymentRow(
          payment: p,
          currency: currency,
        )),
      ],
    ),
  ),
```

**`_PaymentRow` widget** (private, inside project_detail_screen.dart):

```dart
class _PaymentRow extends StatelessWidget {
  final PaymentRecord payment;
  final String currency;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      // Left: green circle with checkmark icon
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color:  kGreen.withOpacity(0.12),
          shape:  BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 16, color: kGreen),
      ),
      const SizedBox(width: 12),
      // Center: note (bold) + date below
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payment.note.isNotEmpty ? payment.note : 'Payment received',
            style: kStyleBodyBold,
          ),
          Text(payment.date, style: kStyleCaption),
        ],
      )),
      // Right: amount in kGreen
      Text(
        '+ ${fmtCurrency(payment.amount, currency)}',
        style: kStyleBodyBold.copyWith(color: kGreen),
      ),
    ]),
  );
}
```

---

# PART 2 — SERVICE CATEGORY UI

## 2A. Update `lib/sheets/add_client_sheet.dart`

Replace the hardcoded `SegmentedButton` for client type with a dynamic category selector.

**Remove:**
```dart
// OLD — delete this:
SegmentedButton<String>(
  segments: [
    ButtonSegment(value: 'website', label: Text('🌐 Website')),
    ButtonSegment(value: 'graphic', label: Text('🎨 Graphic Design')),
  ],
  ...
)
```

**Replace with** a `_CategorySelector` widget (defined in `lib/widgets/category_selector.dart`):

```dart
// In add_client_sheet.dart:
SectionLabel('Primary Service *')
SizedBox(height: 8)
_CategorySelector(
  categories:    settingsProvider.serviceCategories,
  selected:      _selectedCategory,
  onSelected:    (cat) => setState(() => _selectedCategory = cat),
  onAddCustom:   (newCat) async {
    await settingsProvider.addServiceCategory(newCat);
    setState(() => _selectedCategory = newCat);
  },
)
```

The selected value is stored as `String _selectedCategory` — initialized to `settingsProvider.serviceCategories.first`.

On submit, set `client.primaryCategory = _selectedCategory`.

---

## 2B. Update `lib/sheets/add_project_sheet.dart`

**Remove** the hardcoded type `SegmentedButton`.

**Replace** with the same `_CategorySelector` widget, but labeled "Project Category *":

```dart
SectionLabel('Project Category *')
SizedBox(height: 8)
_CategorySelector(
  categories:  settingsProvider.serviceCategories,
  selected:    _selectedCategory,
  onSelected:  (cat) => setState(() => _selectedCategory = cat),
  onAddCustom: (newCat) async {
    await settingsProvider.addServiceCategory(newCat);
    setState(() => _selectedCategory = newCat);
  },
)
```

On submit, set `project.category = _selectedCategory`.

---

## 2C. Create `lib/widgets/category_selector.dart`

A reusable widget used in both add_client_sheet and add_project_sheet.

```dart
// CategorySelector
//
// Displays existing categories as horizontally-scrollable selectable chips.
// The last chip is always "+ Custom" which opens an inline text field.
//
// Layout:
//
// [ Web Dev ✓ ] [ Branding ] [ SEO ] [ + Custom ]
//
// Selected chip: kBlack background, kWhite text, no border
// Unselected chip: kBgCardAlt background, kTextSecondary text, kBorder border
// "+ Custom" chip: kLime.withOpacity(0.15) background, kBlack text, kLime border
//
// When "+ Custom" is tapped:
//   Show an inline TextFormField below the chips:
//   [ _____________________ ] [ Add ]
//   On "Add" button tap:
//     - call onAddCustom(typedName)
//     - dismiss the inline field
//     - select the newly added category
//
// Parameters:
//   List<String> categories    — from settingsProvider.serviceCategories
//   String? selected           — currently selected category name
//   ValueChanged<String> onSelected   — called when user taps a chip
//   ValueChanged<String> onAddCustom  — called with the new name to add globally

class CategorySelector extends StatefulWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onAddCustom;
  // ...
}
```

**Full widget implementation requirements:**

- Wrap chips in a `Wrap(spacing: 8, runSpacing: 8)` — not a horizontal scroll — so all chips wrap to the next line if needed
- Each category chip is a `GestureDetector` wrapping a `Container` with `BorderRadius.circular(20)` and the chip styling described above
- The "+ Custom" chip is always the last item in the wrap
- When in "add custom" mode, show a `Row` with a `TextFormField` (autofocus) and a small "Add" `TextButton` below the chip wrap
- Pressing "Add" with an empty field does nothing
- Pressing "Add" with a non-empty field: calls `onAddCustom(value)`, hides the text field, selects the new category

---

## 2D. Update `lib/screens/client_list_screen.dart`

Replace all references to `client.type` with `client.primaryCategory`.

Replace the hardcoded type badge logic:

```dart
// OLD:
Badge(label: client.type == 'website' ? '🌐 Web' : '🎨 Graphic', color: ...)

// NEW:
Badge(label: client.primaryCategory, color: _categoryColor(client.primaryCategory))
```

Add a `_categoryColor` helper at the top of the file:

```dart
// Deterministically assign a color to a category name using a hash.
// This ensures the same category always gets the same color across the app.
Color _categoryColor(String category) {
  const colors = [kBlue, kPink, kGreen, kOrange, kYellow, Color(0xFF8b5cf6), Color(0xFF06b6d4)];
  return colors[category.hashCode.abs() % colors.length];
}
```

---

## 2E. Update `lib/screens/client_detail_screen.dart`

Replace `client.type` badge with `client.primaryCategory` badge using the same `_categoryColor()` helper.

---

## 2F. Update `lib/screens/dashboard_screen.dart`

In the active projects section, replace the type emoji logic:

```dart
// OLD:
Text(p.type == 'website' ? '🌐' : '🎨')

// NEW:
Text(_categoryEmoji(p.project.category))

// Add this helper (use a generic tag emoji as fallback):
String _categoryEmoji(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('web'))     return '🌐';
  if (lower.contains('design') || lower.contains('graphic') || lower.contains('brand')) return '🎨';
  if (lower.contains('mobile') || lower.contains('app'))   return '📱';
  if (lower.contains('video'))   return '🎬';
  if (lower.contains('seo'))     return '🔍';
  if (lower.contains('copy') || lower.contains('write'))   return '✍️';
  if (lower.contains('photo'))   return '📷';
  return '💼';  // default fallback
}
```

In the client strip section, replace the hardcoded type label:

```dart
// OLD:
Text(c.type == 'website' ? '🌐 Web' : '🎨 Design')

// NEW:
Text('${_categoryEmoji(c.primaryCategory)} ${c.primaryCategory}',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: kStyleCaption.copyWith(fontSize: 10),
)
```

---

## 2G. Create `lib/screens/service_categories_screen.dart`

A management screen where the user can view, add, rename, and delete their service categories.

### Navigation

Accessible from Settings screen via a "Service Categories" list tile under the "YOUR SERVICES" section.

### Layout

```
AppBar: "Service Categories"

Body:
  SectionLabel("YOUR CATEGORIES")
  Caption: "These appear when adding clients and projects."

  ReorderableListView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    onReorder: (old, newIdx) => _reorderCategory(old, newIdx),
    itemBuilder: (ctx, i) => _CategoryTile(categories[i])
  )

  SizedBox(height: 16)

  [+ Add New Category] button  ← outlined, full-width, kLime accent
```

### `_CategoryTile`

Each tile shows:
- `[≡ drag handle]` — `ReorderableDragStartListener`
- Category name (bold)
- `[Edit icon]` — taps to open an inline `TextField` to rename in-place
- `[Delete icon]` — shows `showConfirmDialog` then calls `settingsProvider.removeServiceCategory(name)`

Inline rename mode:
- When Edit is tapped, the `Text` widget animates into a `TextField` prefilled with the current name
- Confirm with a checkmark button or by pressing Enter
- Cancel with an X button (reverts to original name)
- Calls `settingsProvider.renameServiceCategory(oldName, newName)` on confirm

Prevent deleting the last category — show a `SnackBar`: "You must have at least one service category."

### Add New Category

```dart
// Full-width outlined button at the bottom:
OutlinedButton.icon(
  onPressed: _showAddDialog,
  icon: Icon(Icons.add_rounded),
  label: Text('Add New Category'),
  style: OutlinedButton.styleFrom(
    foregroundColor: kBlack,
    side: BorderSide(color: kLime, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    minimumSize: Size(double.infinity, 48),
  ),
)

void _showAddDialog() {
  showDialog(
    context: context,
    builder: (ctx) {
      final ctrl = TextEditingController();
      return AlertDialog(
        title: Text('New Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: 'e.g. Motion Design'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              settingsProvider.addServiceCategory(ctrl.text);
              Navigator.pop(ctx);
            },
            child: Text('Add'),
          ),
        ],
      );
    },
  );
}
```

---

## 2H. Update `lib/screens/settings_screen.dart`

Add two new sections:

```dart
// ── NEW SECTION: YOUR SERVICES (add ABOVE the Dashboard section) ──────────
SectionLabel('YOUR SERVICES')
ListTile(
  leading: Icon(Icons.category_rounded, color: kTextSecondary),
  title: Text('Service Categories', style: kStyleBodyBold),
  subtitle: Text('Manage the types of work you offer', style: kStyleBody),
  trailing: Icon(Icons.chevron_right_rounded, color: kTextMuted),
  onTap: () => Navigator.push(context, CupertinoPageRoute(
    builder: (_) => const ServiceCategoriesScreen()
  )),
)
Divider(color: kBorder, height: 1)
```

---

## 2I. Update `lib/services/export_service.dart`

In `_buildProjectsSheet()`, replace the hardcoded type column:

```dart
// OLD:
TextCellValue(p.type == 'website' ? 'Website' : 'Graphic Design'),

// NEW:
TextCellValue(p.category),
```

In `_buildClientsSheet()`, replace the hardcoded type column:

```dart
// OLD:
TextCellValue(c.type == 'website' ? 'Website' : 'Graphic Design'),

// NEW:
TextCellValue(c.primaryCategory),
```

---

## 2J. Update Seed Data — `lib/seed_data.dart`

Replace hardcoded `type` fields with `category` and `primaryCategory`:

```dart
// Client 1 (Sarah Mitchell):
..primaryCategory = 'Web Development'
// Project (Portfolio Redesign):
..category = 'Web Development'

// Client 2 (James Okafor):
..primaryCategory = 'Graphic Design'
// Project (Brand Identity Pack):
..category = 'Graphic Design'
```

---

# PART 3 — FULL FILE LIST

| File | Action |
|---|---|
| `lib/models/payment_record.dart` | **Create new** — new Hive model |
| `lib/models/project.dart` | Modify — rename `type` → `category`, add `payments` field |
| `lib/models/client.dart` | Modify — rename `type` → `primaryCategory` |
| `lib/models/app_settings.dart` | Modify — add `serviceCategories` field |
| `lib/providers/settings_provider.dart` | Modify — add category management methods |
| `lib/providers/data_provider.dart` | Modify — add `recordPayment()` method |
| `lib/sheets/add_client_sheet.dart` | Modify — replace `SegmentedButton` with `CategorySelector` |
| `lib/sheets/add_project_sheet.dart` | Modify — replace `SegmentedButton` with `CategorySelector` |
| `lib/sheets/record_payment_sheet.dart` | **Create new** |
| `lib/widgets/category_selector.dart` | **Create new** |
| `lib/screens/project_detail_screen.dart` | Modify — add Record Payment button + Payment History card |
| `lib/screens/client_list_screen.dart` | Modify — replace type badge with category badge |
| `lib/screens/client_detail_screen.dart` | Modify — replace type badge with category badge |
| `lib/screens/dashboard_screen.dart` | Modify — replace type emoji/label with dynamic helpers |
| `lib/screens/service_categories_screen.dart` | **Create new** |
| `lib/screens/settings_screen.dart` | Modify — add Service Categories list tile |
| `lib/services/export_service.dart` | Modify — replace hardcoded type columns |
| `lib/seed_data.dart` | Modify — use `category` and `primaryCategory` |
| `main.dart` | Modify — register `PaymentRecordAdapter` |

---

# FINAL CHECKLIST

- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs` after creating `PaymentRecord` and updating model fields
- [ ] `PaymentRecord` uses `typeId: 4` — never used by any other model
- [ ] `PaymentRecordAdapter` registered in `main.dart` before any box is opened
- [ ] `project.type` property does NOT exist anywhere in the codebase — fully replaced by `project.category`
- [ ] `client.type` property does NOT exist anywhere in the codebase — fully replaced by `client.primaryCategory`
- [ ] `@HiveField(3)` index preserved on `Project` — only the Dart property name changed
- [ ] `@HiveField(5)` index preserved on `Client` — only the Dart property name changed
- [ ] `AppSettings.serviceCategories` field uses the next available `@HiveField` index (26)
- [ ] `recordPayment()` clamps `project.remaining` to `>= 0.0` — never goes negative
- [ ] `recordPayment()` adds amount to `project.upfront` AND subtracts from `project.remaining`
- [ ] `recordPayment()` fires payment-complete notification only when `remaining` transitions from `> 0` to `== 0`
- [ ] "Record Payment" button only shown when `project.remaining > 0`
- [ ] "Pay in full" chip in `RecordPaymentSheet` fills the amount field with exact `currentRemaining`
- [ ] Live preview in `RecordPaymentSheet` updates on every keystroke in the amount field
- [ ] Overpayment warning shown in red when `enteredAmount > currentRemaining`
- [ ] Payment History card only shown when `project.payments.isNotEmpty`
- [ ] Payments in history displayed in reverse chronological order (newest first)
- [ ] `CategorySelector` uses `Wrap` (not horizontal scroll) — chips wrap to next line
- [ ] `CategorySelector` "+ Custom" chip opens inline text field — NOT a dialog
- [ ] `addServiceCategory()` is case-insensitive duplicate check — "web dev" and "Web Dev" count as the same
- [ ] `removeServiceCategory()` prevents deleting last category
- [ ] `_categoryColor()` uses `hashCode.abs() % colors.length` — deterministic, same category always same color
- [ ] `_categoryEmoji()` on dashboard uses keyword matching with `'💼'` as fallback
- [ ] `ServiceCategoriesScreen` uses `ReorderableListView` with drag handles
- [ ] Inline rename in `ServiceCategoriesScreen` confirms on Enter key and checkmark button
- [ ] Seed data uses `primaryCategory` and `category` — no `type` field anywhere in seed data
- [ ] Export service uses `p.category` and `c.primaryCategory` — no hardcoded type strings
