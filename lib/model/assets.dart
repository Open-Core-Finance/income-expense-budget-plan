abstract class Assets {

  final String uid;
  String name = "";
  String description = "";
  String currencyUid = "1";

  Assets({
    required this.uid
  });

  // Convert a Assets into a Map. The keys must correspond to the names of the columns in the database.
  Map<String, Object?> toMap() {
    return {
      'uid': uid,
      'name': name,
      'currency_uid': currencyUid
    };
  }

  // Implement toString to make it easier to see information about
  // each Assets when using the print statement.
  @override
  String toString() {
    return '{${attributeString()}}';
  }

  String attributeString() {
    return 'uid: $uid, name: $name, currencyUid: $currencyUid';
  }
}

class CashAccount extends Assets {
  double availableAmount = 0;
  CashAccount({required super.uid});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({
      'available_amount': availableAmount
    });
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},availableAmount: $availableAmount';
  }
}

class BankCasaAccount extends Assets {
  double availableAmount = 0;
  BankCasaAccount({required super.uid});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({
      'available_amount': availableAmount
    });
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},availableAmount: $availableAmount';
  }
}

class LoanAccount extends Assets {
  double loanAmount = 0;
  LoanAccount({required super.uid});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({
      'loan_amount': loanAmount
    });
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},loanAmount: $loanAmount';
  }
}

class TermDepositAccount extends Assets {
  double depositAmount = 0;
  TermDepositAccount({required super.uid});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({
      'deposit_amount': depositAmount
    });
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},depositAmount: $depositAmount';
  }
}

class EWallet extends Assets {
  double availableAmount = 0;
  EWallet({required super.uid});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({
      'available_amount': availableAmount
    });
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},availableAmount: $availableAmount';
  }
}

class CreditCard extends Assets {
  double availableAmount = 0;
  double creditLimit = 0;
  CreditCard({required super.uid});

  @override
  Map<String, Object?> toMap() {
    var result = super.toMap();
    result.addAll({
      'available_amount': availableAmount,
      'credit_limit': creditLimit
    });
    return result;
  }

  @override
  String attributeString() {
    return '${super.attributeString()},availableAmount: $availableAmount, creditLimit: $creditLimit';
  }
}
