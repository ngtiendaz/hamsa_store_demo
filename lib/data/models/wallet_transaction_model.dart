enum WalletTransactionType {
  deposit,
  payment,
  refund,
  manual_adjustment;

  static WalletTransactionType fromString(String value) {
    switch (value) {
      case 'deposit':
        return WalletTransactionType.deposit;
      case 'payment':
        return WalletTransactionType.payment;
      case 'refund':
        return WalletTransactionType.refund;
      default:
        return WalletTransactionType.manual_adjustment;
    }
  }

  String toStringValue() {
    switch (this) {
      case WalletTransactionType.deposit:
        return 'deposit';
      case WalletTransactionType.payment:
        return 'payment';
      case WalletTransactionType.refund:
        return 'refund';
      case WalletTransactionType.manual_adjustment:
        return 'manual_adjustment';
    }
  }

  String get label {
    switch (this) {
      case WalletTransactionType.deposit:
        return 'Nạp tiền';
      case WalletTransactionType.payment:
        return 'Thanh toán';
      case WalletTransactionType.refund:
        return 'Hoàn tiền';
      case WalletTransactionType.manual_adjustment:
        return 'Rút tiền';
    }
  }
}

class WalletTransactionModel {
  final String id;
  final String walletId;
  final String userId;
  final WalletTransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? relatedOrderId;
  final String? relatedReturnOrderId;
  final String? note;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.relatedOrderId,
    this.relatedReturnOrderId,
    this.note,
    required this.createdAt,
  });

  bool get isAdd {
    return type == WalletTransactionType.deposit || type == WalletTransactionType.refund;
  }

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      userId: json['user_id'] as String,
      type: WalletTransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      balanceBefore: (json['balance_before'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      relatedOrderId: json['related_order_id'] as String?,
      relatedReturnOrderId: json['related_return_order_id'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'user_id': userId,
      'type': type.toStringValue(),
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'related_order_id': relatedOrderId,
      'related_return_order_id': relatedReturnOrderId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
