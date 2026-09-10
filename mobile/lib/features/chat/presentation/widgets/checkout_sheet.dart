import 'package:flutter/material.dart';

class CheckoutSheet extends StatefulWidget {
  final double amount;
  final String currency;
  final String title;
  final VoidCallback onComplete;

  const CheckoutSheet({
    super.key,
    required this.amount,
    required this.currency,
    required this.title,
    required this.onComplete,
  });

  static void show(
    BuildContext context, {
    required double amount,
    required String currency,
    required String title,
    required VoidCallback onComplete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => CheckoutSheet(
        amount: amount,
        currency: currency,
        title: title,
        onComplete: () {
          Navigator.pop(ctx);
          onComplete();
        },
      ),
    );
  }

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  String _selectedPaymentMethod = 'Nexora Wallet';
  bool _isProcessing = false;

  void _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Successfully paid ${widget.currency} ${widget.amount.toStringAsFixed(2)}!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF7C3AED), size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nexora Pay Checkout', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Encrypted 256-bit Escrow Settlement', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Immediate settlement', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                  Text(
                    '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF7C3AED)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text('SELECT PAYMENT METHOD', style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),

            _buildPaymentOption(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Nexora Balance',
              subtitle: 'Available: \$1,240.00',
              value: 'Nexora Wallet',
            ),
            _buildPaymentOption(
              icon: Icons.credit_card_rounded,
              title: 'Visa •••• 4242',
              subtitle: 'Expires 12/28',
              value: 'Visa',
            ),
            _buildPaymentOption(
              icon: Icons.apple_rounded,
              title: 'Apple Pay / Google Pay',
              subtitle: 'One-touch authorization',
              value: 'Apple Pay',
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isProcessing ? null : _processPayment,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Pay ${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF7C3AED) : cs.outline.withValues(alpha: 0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (val) => setState(() => _selectedPaymentMethod = val ?? value),
        secondary: Icon(icon, color: isSelected ? const Color(0xFF7C3AED) : cs.onSurface.withValues(alpha: 0.6)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: cs.onSurface.withValues(alpha: 0.5))),
      ),
    );
  }
}
