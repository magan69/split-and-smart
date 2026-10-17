# SplitSmart

A Dart expense splitter that tracks shared group expenses and calculates how much each member owes or should receive. Built for DevSource DevCamp 2.0 (Flutter & Dart), Week 1, Project 1.

## Features

**Required**
- Add group members with unique names
- Record expenses with a title, positive amount, payer, category and participants, split equally
- List expenses and filter them by member or category
- Calculate each member's total paid, share owed and net balance
- Clear errors for duplicate members, unknown members, invalid amounts and empty participant lists

**Optional extensions**
- Edit and delete expenses (an edit is validated before it replaces the old expense)
- Summaries returned as Dart records: `(paid, owed, net)`
- Consistent rounding: when an amount does not divide evenly, the leftover rupees go one each to the first participants, so shares always add up to the total

## How to run

**DartPad:** open https://dartpad.dev, paste the contents of `main.dart`, and click Run.

**Local Dart:**

```
dart run main.dart
```

## Example

```dart
final group = ExpenseGroup();
group.addMember('Asha');
group.addMember('Ravi');
group.addMember('Neha');
group.addExpense(
  title: 'Dinner', amount: 900, paidBy: 'Asha',
  category: 'Food',
  splitBetween: ['Asha', 'Ravi', 'Neha'],
);
group.printBalances();
```

Output:

```
--- Balances ---
Asha: paid 900, share 300, net 600 -> should receive INR 600
Ravi: paid 0, share 300, net -300 -> owes INR 300
Neha: paid 0, share 300, net -300 -> owes INR 300
```

## Demo scenarios in main()

1. The Dinner example from the brief
2. A trip with three expenses, three different payers, and a member who skips one expense
3. Filtering by member and by category
4. Every error case (duplicate member, empty name, negative or zero amount, empty participants, unknown payer, unknown participant, unknown expense id)
5. Editing and deleting expenses

## Project structure

- `SplitSmartException`: custom exception with clear messages
- `Expense`: one recorded expense
- `ExpenseGroup`: members, expenses, validation, filtering, balances
- `main()`: demo scenarios

## Skills used

Functions, collections, classes, validation, exception handling, records and problem solving.

## Author

magan shandilya
