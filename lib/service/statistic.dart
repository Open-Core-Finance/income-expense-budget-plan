class Statistic {
  double totalIncome = 0;
  double totalExpense = 0;
  double totalTransferOut = 0;
  double totalTransferIn = 0;
  double totalTransfer = 0;
  double totalSharedBillPaid = 0;
  double totalSharedBillReturn = 0;
  double totalFeePaid = 0;
  double totalLend = 0;
  double totalBorrow = 0;

  @override
  String toString() {
    return '{${toAttrString()}';
  }

  String toAttrString() => '"totalIncome": $totalIncome, "totalExpense": $totalExpense,'
      '"totalTransferOut": $totalTransferOut, "totalTransferIn": $totalTransferIn, "totalSharedBillPaid": $totalSharedBillPaid,'
      '"totalSharedBillReturn": $totalSharedBillReturn, "totalFeePaid": $totalFeePaid, "totalLend": $totalLend, "totalBorrow": $totalBorrow';
}
