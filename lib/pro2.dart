import 'package:flutter/material.dart';
import 'package:stock_app/pro.dart';
import 'package:stock_app/payment.dart';

class Pro2 extends StatefulWidget {
  const Pro2({super.key});

  @override
  State<Pro2> createState() => _Pro2State();
}

class _Pro2State extends State<Pro2> {
  String _selectedPlan = 'monthly'; // 'monthly' or 'yearly'

  @override
  Widget build(BuildContext context) {
    final isMonthlySelected = _selectedPlan == 'monthly';
    final planPrice = isMonthlySelected ? '\$4.99/month' : '\$49.90/year';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF091625),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Pro()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Upgrade to Pro',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Choose your plan',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPlan = 'monthly';
                      });
                    },
                    child: Container(
                      height: 87,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF091625),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMonthlySelected ? Colors.green : Colors.grey,
                          width: isMonthlySelected ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isMonthlySelected
                                          ? Colors.green
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: isMonthlySelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.green,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Monthly',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  '\$4.99/month',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPlan = 'yearly';
                      });
                    },
                    child: Container(
                      height: 87,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF091625),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !isMonthlySelected
                              ? Colors.green
                              : Colors.grey,
                          width: !isMonthlySelected ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: !isMonthlySelected
                                          ? Colors.green
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: !isMonthlySelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.green,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Yearly',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  '\$49.90/year',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Selected Plan',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF091625),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isMonthlySelected
                                    ? 'Monthly Plan'
                                    : 'Yearly Plan',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              const Text(
                                'Pro features unlocked',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            planPrice,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPaymentMethodCard(
                        'assets/images/symbol.png',
                        'Apple Pay',
                      ),
                      _buildPaymentMethodCard(
                        'assets/images/card.png',
                        'Credit Card',
                      ),
                      _buildPaymentMethodCard(
                        'assets/images/google-pay.png',
                        'Google Pay',
                      ),
                      _buildPaymentMethodCard(
                        'assets/images/paypal.png',
                        'PayPal',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Payment()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(double.infinity, 67),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Center(
                      child: Text(
                        'Continue to Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String imagePath, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF091625),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 32,
            width: 40,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 32,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.payment, color: Colors.grey, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
