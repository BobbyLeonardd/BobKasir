/// Data dikumpulkan di layar checkout dan diteruskan ke layar pembayaran.
class CheckoutData {
  final String? customerName;
  final String? tableNumber;
  final String? note;
  final int subtotal;
  final int discountTotal;
  final int taxTotal;
  final int serviceChargeTotal;
  final int grandTotal;

  const CheckoutData({
    this.customerName,
    this.tableNumber,
    this.note,
    required this.subtotal,
    this.discountTotal = 0,
    this.taxTotal = 0,
    this.serviceChargeTotal = 0,
    required this.grandTotal,
  });
}
