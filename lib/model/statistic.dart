class Statistic {
  late double totalIncome;
  late double totalExpense;
  late double totalTransferOut;
  late double totalTransferIn;
  late double totalTransfer;
  late double totalSharedBillPaid;
  late double totalSharedBillReturn;
  late double totalFeePaid;
  late double totalLend;
  late double totalBorrow;

  Statistic({
    double? totalIncome,
    double? totalExpense,
    double? totalTransferOut,
    double? totalTransferIn,
    double? totalTransfer,
    double? totalSharedBillPaid,
    double? totalSharedBillReturn,
    double? totalFeePaid,
    double? totalLend,
    double? totalBorrow,
  }) {
    this.totalIncome = totalIncome ?? 0;
    this.totalExpense = totalExpense ?? 0;
    this.totalTransferOut = totalTransferOut ?? 0;
    this.totalTransferIn = totalTransferIn ?? 0;
    this.totalTransfer = totalTransfer ?? 0;
    this.totalSharedBillPaid = totalSharedBillPaid ?? 0;
    this.totalSharedBillReturn = totalSharedBillReturn ?? 0;
    this.totalFeePaid = totalFeePaid ?? 0;
    this.totalLend = totalLend ?? 0;
    this.totalBorrow = totalBorrow ?? 0;
  }

  @override
  String toString() {
    return '{${toAttrString()}}';
  }

  String toAttrString() => '"totalIncome": $totalIncome, "totalExpense": $totalExpense,'
      '"totalTransferOut": $totalTransferOut, "totalTransferIn": $totalTransferIn, "totalSharedBillPaid": $totalSharedBillPaid,'
      '"totalSharedBillReturn": $totalSharedBillReturn, "totalFeePaid": $totalFeePaid, "totalLend": $totalLend, "totalBorrow": $totalBorrow';

  void combineWith(Statistic statistic) {
    totalIncome += statistic.totalIncome;
    totalExpense += statistic.totalExpense;
    totalSharedBillReturn += statistic.totalSharedBillReturn;
    totalSharedBillPaid += statistic.totalSharedBillPaid;
    totalBorrow += statistic.totalBorrow;
    totalLend += statistic.totalLend;
    totalTransferIn += statistic.totalTransferIn;
    totalTransferOut += statistic.totalTransferOut;
    totalTransfer += statistic.totalTransfer;
    totalFeePaid += statistic.totalFeePaid;
  }
}
