class BillFilterModel {
  final String? searchQuery;
  final List<String>? statusFilters;
  final List<String>? typeFilters;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sortBy;
  final bool ascending;

  const BillFilterModel({
    this.searchQuery,
    this.statusFilters,
    this.typeFilters,
    this.startDate,
    this.endDate,
    this.sortBy = 'created_at',
    this.ascending = false,
  });

  BillFilterModel copyWith({
    String? searchQuery,
    List<String>? statusFilters,
    List<String>? typeFilters,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    bool? ascending,
  }) {
    return BillFilterModel(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilters: statusFilters ?? this.statusFilters,
      typeFilters: typeFilters ?? this.typeFilters,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'search_query': searchQuery,
      'status_filters': statusFilters,
      'type_filters': typeFilters,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'sort_by': sortBy,
      'ascending': ascending,
    };
  }

  bool get hasActiveFilters {
    return searchQuery != null ||
        (statusFilters != null && statusFilters!.isNotEmpty) ||
        (typeFilters != null && typeFilters!.isNotEmpty) ||
        startDate != null ||
        endDate != null;
  }
}
