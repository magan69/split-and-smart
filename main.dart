// ---------- Custom exception ----------
class SplitSmartException implements Exception {
  final String message;
  SplitSmartException(this.message);

  @override
  String toString() => 'Error: $message';
}

// A record type: one member's summary
typedef Summary = ({int paid, int owed, int net});

// ---------- Expense ----------
class Expense {
  final int id;
  final String title;
  final int amount;
  final String paidBy;
  final String category;
  final List<String> participants;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.category,
    required this.participants,
  });
}

// ---------- ExpenseGroup ----------
class ExpenseGroup {
  final List<String> members = [];
  final List<Expense> _expenses = [];
  int _nextId = 1;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  // ----- Members -----
  void addMember(String name) {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw SplitSmartException('Member name cannot be empty');
    }
    if (members.contains(clean)) {
      throw SplitSmartException('Member "$clean" already exists');
    }
    members.add(clean);
  }

  void _requireMember(String name) {
    if (!members.contains(name)) {
      throw SplitSmartException('Unknown member "$name"');
    }
  }

  // ----- Validation (shared by add and edit) -----
  void _validate({
    required String title,
    required int amount,
    required String paidBy,
    required List<String> splitBetween,
  }) {
    if (title.trim().isEmpty) {
      throw SplitSmartException('Title cannot be empty');
    }
    if (amount <= 0) {
      throw SplitSmartException('Amount must be greater than 0 (got $amount)');
    }
    if (splitBetween.isEmpty) {
      throw SplitSmartException('Participant list cannot be empty');
    }
    if (splitBetween.toSet().length != splitBetween.length) {
      throw SplitSmartException('Participant list has duplicate names');
    }
    _requireMember(paidBy);
    for (final name in splitBetween) {
      _requireMember(name);
    }
  }

  // ----- Add / edit / delete -----
  Expense addExpense({
    required String title,
    required int amount,
    required String paidBy,
    required String category,
    required List<String> splitBetween,
  }) {
    _validate(
      title: title,
      amount: amount,
      paidBy: paidBy,
      splitBetween: splitBetween,
    );
    final expense = Expense(
      id: _nextId++,
      title: title.trim(),
      amount: amount,
      paidBy: paidBy,
      category: category.trim(),
      participants: List.of(splitBetween),
    );
    _expenses.add(expense);
    return expense;
  }

  int _indexOf(int id) {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw SplitSmartException('No expense with id $id');
    }
    return index;
  }

  // Validates BEFORE replacing, so a bad edit never loses the old expense.
  void editExpense({
    required int id,
    required String title,
    required int amount,
    required String paidBy,
    required String category,
    required List<String> splitBetween,
  }) {
    final index = _indexOf(id);
    _validate(
      title: title,
      amount: amount,
      paidBy: paidBy,
      splitBetween: splitBetween,
    );
    _expenses[index] = Expense(
      id: id,
      title: title.trim(),
      amount: amount,
      paidBy: paidBy,
      category: category.trim(),
      participants: List.of(splitBetween),
    );
  }

  void deleteExpense(int id) {
    _expenses.removeAt(_indexOf(id));
  }

  // ----- Listing and filtering -----
  List<Expense> filterByMember(String name) {
    _requireMember(name);
    return _expenses
        .where((e) => e.paidBy == name || e.participants.contains(name))
        .toList();
  }

  List<Expense> filterByCategory(String category) {
    final wanted = category.trim().toLowerCase();
    return _expenses.where((e) => e.category.toLowerCase() == wanted).toList();
  }

  void printExpenses(List<Expense> list, {String heading = 'All expenses'}) {
    print('--- $heading ---');
    if (list.isEmpty) {
      print('(none)');
      return;
    }
    for (final e in list) {
      print('#${e.id} ${e.title} | INR ${e.amount} | paid by ${e.paidBy} '
          '| ${e.category} | split: ${e.participants.join(', ')}');
    }
  }

  // ----- Balances -----
  // Rounding rule: the share is amount ~/ n, and the leftover rupees
  // (amount % n) go one each to the first participants in the list.
  // This way the shares always add up exactly to the amount.
  Map<String, int> _sharesOf(Expense e) {
    final n = e.participants.length;
    final base = e.amount ~/ n;
    final remainder = e.amount % n;
    final shares = <String, int>{};
    for (var i = 0; i < n; i++) {
      shares[e.participants[i]] = base + (i < remainder ? 1 : 0);
    }
    return shares;
  }

  // Returns a record per member: (paid, owed, net)
  Map<String, Summary> getSummaries() {
    final paid = {for (final m in members) m: 0};
    final owed = {for (final m in members) m: 0};

    for (final e in _expenses) {
      paid[e.paidBy] = paid[e.paidBy]! + e.amount;
      _sharesOf(e).forEach((name, share) {
        owed[name] = owed[name]! + share;
      });
    }

    return {
      for (final m in members)
        m: (paid: paid[m]!, owed: owed[m]!, net: paid[m]! - owed[m]!),
    };
  }

  void printBalances() {
    print('--- Balances ---');
    getSummaries().forEach((name, s) {
      final String verdict;
      if (s.net > 0) {
        verdict = 'should receive INR ${s.net}';
      } else if (s.net < 0) {
        verdict = 'owes INR ${-s.net}';
      } else {
        verdict = 'is settled up';
      }
      print('$name: paid ${s.paid}, share ${s.owed}, net ${s.net} -> $verdict');
    });
  }
}

// ---------- Demo helper: runs an action and prints any error ----------
void attempt(String label, void Function() action) {
  try {
    action();
    print('$label -> OK');
  } on SplitSmartException catch (e) {
    print('$label -> $e');
  }
}

// ---------- main ----------
void main() {
  // ===== Scenario 1: the spec example =====
  print('===== Scenario 1: Dinner =====');
  final group = ExpenseGroup();
  group.addMember('Asha');
  group.addMember('Ravi');
  group.addMember('Neha');

  group.addExpense(
    title: 'Dinner',
    amount: 900,
    paidBy: 'Asha',
    category: 'Food',
    splitBetween: ['Asha', 'Ravi', 'Neha'],
  );
  group.printBalances();

  // ===== Scenario 2: trip, multiple payers, partial participation =====
  print('\n===== Scenario 2: Trip =====');
  final trip = ExpenseGroup();
  trip.addMember('Asha');
  trip.addMember('Ravi');
  trip.addMember('Neha');

  trip.addExpense(
    title: 'Hotel',
    amount: 3000,
    paidBy: 'Ravi',
    category: 'Stay',
    splitBetween: ['Asha', 'Ravi', 'Neha'],
  );
  trip.addExpense(
    title: 'Cab',
    amount: 600,
    paidBy: 'Neha',
    category: 'Travel',
    splitBetween: ['Ravi', 'Neha'], // Asha not in this one
  );
  trip.addExpense(
    title: 'Lunch',
    amount: 1000, // does not divide evenly by 3: shows the rounding rule
    paidBy: 'Asha',
    category: 'Food',
    splitBetween: ['Asha', 'Ravi', 'Neha'],
  );

  trip.printExpenses(trip.expenses);
  trip.printBalances();

  // ===== Filtering =====
  print('\n===== Filtering =====');
  trip.printExpenses(trip.filterByMember('Asha'), heading: 'Involving Asha');
  trip.printExpenses(trip.filterByCategory('food'), heading: 'Category: food');

  // ===== Using the record summary directly =====
  print('\n===== Record summary =====');
  final ravi = trip.getSummaries()['Ravi']!;
  print('Ravi -> paid: ${ravi.paid}, owed: ${ravi.owed}, net: ${ravi.net}');

  // ===== Error handling =====
  print('\n===== Error cases =====');
  attempt('Duplicate member', () => trip.addMember('Asha'));
  attempt('Empty member name', () => trip.addMember('   '));
  attempt(
    'Negative amount',
    () => trip.addExpense(
      title: 'Bad', amount: -50, paidBy: 'Asha',
      category: 'Misc', splitBetween: ['Asha'],
    ),
  );
  attempt(
    'Zero amount',
    () => trip.addExpense(
      title: 'Bad', amount: 0, paidBy: 'Asha',
      category: 'Misc', splitBetween: ['Asha'],
    ),
  );
  attempt(
    'Empty participants',
    () => trip.addExpense(
      title: 'Bad', amount: 100, paidBy: 'Asha',
      category: 'Misc', splitBetween: [],
    ),
  );
  attempt(
    'Unknown payer',
    () => trip.addExpense(
      title: 'Bad', amount: 100, paidBy: 'Zoya',
      category: 'Misc', splitBetween: ['Asha'],
    ),
  );
  attempt(
    'Unknown participant',
    () => trip.addExpense(
      title: 'Bad', amount: 100, paidBy: 'Asha',
      category: 'Misc', splitBetween: ['Asha', 'Zoya'],
    ),
  );
  attempt('Filter unknown member', () => trip.filterByMember('Zoya'));
  attempt('Delete unknown id', () => trip.deleteExpense(99));
  print('Expenses still stored: ${trip.expenses.length}'); // should be 3

  // ===== Edit and delete =====
  print('\n===== Edit / delete =====');
  trip.editExpense(
    id: 3,
    title: 'Lunch',
    amount: 900,
    paidBy: 'Asha',
    category: 'Food',
    splitBetween: ['Asha', 'Ravi', 'Neha'],
  );
  print('Edited Lunch to 900.');
  trip.printBalances();

  attempt(
    'Bad edit (amount -1)',
    () => trip.editExpense(
      id: 3, title: 'Lunch', amount: -1, paidBy: 'Asha',
      category: 'Food', splitBetween: ['Asha'],
    ),
  );

  trip.deleteExpense(2); // remove the Cab
  print('Deleted Cab.');
  trip.printExpenses(trip.expenses);
  trip.printBalances();
}
