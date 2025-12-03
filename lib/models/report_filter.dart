class ReportFilter {
  // Period
  String periodType; // 'MONTH', 'QUARTER', 'YEAR', 'CUSTOM', 'LAST_7', 'LAST_30', 'LAST_90'
  DateTime? startDate;
  DateTime? endDate;
  
  // Categories and Subcategories
  List<String> selectedCategories;
  List<String> selectedSubcategories;
  bool excludeMode; // true = exclude selected, false = include only selected
  
  // Values
  double? minValue;
  double? maxValue;
  
  // Transaction Type
  bool includeExpenses;
  bool includeIncome;
  bool includeInstallments;
  bool includeSinglePayments;
  bool excludeReversals;
  
  ReportFilter({
    this.periodType = 'MONTH',
    this.startDate,
    this.endDate,
    this.selectedCategories = const [],
    this.selectedSubcategories = const [],
    this.excludeMode = false,
    this.minValue,
    this.maxValue,
    this.includeExpenses = true,
    this.includeIncome = true,
    this.includeInstallments = true,
    this.includeSinglePayments = true,
    this.excludeReversals = true,
  });
  
  // Helper to check if filter is default (no filters applied)
  bool get isDefault {
    return periodType == 'MONTH' &&
           selectedCategories.isEmpty &&
           selectedSubcategories.isEmpty &&
           minValue == null &&
           maxValue == null &&
           includeExpenses &&
           includeIncome &&
           includeInstallments &&
           includeSinglePayments;
  }
  
  // Create a copy with modifications
  ReportFilter copyWith({
    String? periodType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedCategories,
    List<String>? selectedSubcategories,
    bool? excludeMode,
    double? minValue,
    double? maxValue,
    bool? includeExpenses,
    bool? includeIncome,
    bool? includeInstallments,
    bool? includeSinglePayments,
    bool? excludeReversals,
  }) {
    return ReportFilter(
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedSubcategories: selectedSubcategories ?? this.selectedSubcategories,
      excludeMode: excludeMode ?? this.excludeMode,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      includeExpenses: includeExpenses ?? this.includeExpenses,
      includeIncome: includeIncome ?? this.includeIncome,
      includeInstallments: includeInstallments ?? this.includeInstallments,
      includeSinglePayments: includeSinglePayments ?? this.includeSinglePayments,
      excludeReversals: excludeReversals ?? this.excludeReversals,
    );
  }
  
  // Reset to default
  ReportFilter reset() {
    return ReportFilter();
  }
}
