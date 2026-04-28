enum BillType {
  standard,
  proforma,
  commercial,
}

extension BillTypeExtension on BillType {
  String get displayName {
    switch (this) {
      case BillType.standard:
        return 'Standard Invoice';
      case BillType.proforma:
        return 'Proforma Invoice';
      case BillType.commercial:
        return 'Commercial Invoice';
    }
  }

  String get description {
    switch (this) {
      case BillType.standard:
        return 'Regular invoice for goods and services';
      case BillType.proforma:
        return 'Preliminary bill of sale';
      case BillType.commercial:
        return 'Required for international shipments';
    }
  }
}
