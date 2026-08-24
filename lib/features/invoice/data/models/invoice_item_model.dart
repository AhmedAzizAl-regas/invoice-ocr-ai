/// InvoiceItemModel represents a single item inside an Invoice.
class InvoiceItemModel {
  final String id;
  final String invoiceId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Factory constructor to parse from SQLite ResultSet row.
  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }

  /// Converts model back to SQLite parameters.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  /// Copy constructor helper
  InvoiceItemModel copyWith({
    String? id,
    String? invoiceId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
