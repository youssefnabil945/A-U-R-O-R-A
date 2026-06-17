enum BillStatus {
  draft,
  pending,
  paid,
  overdue,
  cancelled,
}

extension BillStatusExtension on BillStatus {
  String get displayName {
    switch (this) {
      case BillStatus.draft:
        return 'Draft';
      case BillStatus.pending:
        return 'Pending';
      case BillStatus.paid:
        return 'Paid';
      case BillStatus.overdue:
        return 'Overdue';
      case BillStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get displayColorHex {
    switch (this) {
      case BillStatus.draft:
        return '9E9E9E'; // Grey
      case BillStatus.pending:
        return 'FFA726'; // Orange
      case BillStatus.paid:
        return '66BB6A'; // Green
      case BillStatus.overdue:
        return 'EF5350'; // Red
      case BillStatus.cancelled:
        return 'BDBDBD'; // Light Grey
    }
  }
}
