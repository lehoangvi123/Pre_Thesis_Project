import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConvertingCurrencyView extends StatefulWidget {
  const ConvertingCurrencyView({Key? key}) : super(key: key);

  @override
  State<ConvertingCurrencyView> createState() =>
      _ConvertingCurrencyViewState();
}

class _ConvertingCurrencyViewState extends State<ConvertingCurrencyView> {
  String fromCurrency = 'VND';
  String toCurrency = 'USD';
  TextEditingController fromAmountController =
      TextEditingController(text: '1000000');
  TextEditingController toAmountController = TextEditingController(text: '0.00');
  String searchFrom = '';
  String searchTo = '';
  Map<String, double> exchangeRates = {};
  bool isLoading = true;
  String errorMessage = '';

  final List<Map<String, String>> currencies = [
    {'code': 'VND', 'name': 'Vietnamese Dong', 'symbol': '₫'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': '\$'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': '\$'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': '\$'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': '\$'},
    {'code': 'NZD', 'name': 'New Zealand Dollar', 'symbol': '\$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'SEK', 'name': 'Swedish Krona', 'symbol': 'kr'},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'symbol': 'kr'},
    {'code': 'DKK', 'name': 'Danish Krone', 'symbol': 'kr'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': '\$'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$'},
    {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'R'},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
    {'code': 'PHP', 'name': 'Philippine Peso', 'symbol': '₱'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': 'ر.س'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '₺'},
    {'code': 'PLN', 'name': 'Polish Zloty', 'symbol': 'zł'},
    {'code': 'CZK', 'name': 'Czech Koruna', 'symbol': 'Kč'},
    {'code': 'HUF', 'name': 'Hungarian Forint', 'symbol': 'Ft'},
    {'code': 'RON', 'name': 'Romanian Leu', 'symbol': 'lei'},
    {'code': 'BGN', 'name': 'Bulgarian Lev', 'symbol': 'лв'},
    {'code': 'HRK', 'name': 'Croatian Kuna', 'symbol': 'kn'},
    {'code': 'ISK', 'name': 'Icelandic Króna', 'symbol': 'kr'},
    {'code': 'CLP', 'name': 'Chilean Peso', 'symbol': '\$'},
    {'code': 'ARS', 'name': 'Argentine Peso', 'symbol': '\$'},
    {'code': 'COP', 'name': 'Colombian Peso', 'symbol': '\$'},
    {'code': 'PEN', 'name': 'Peruvian Sol', 'symbol': 'S/'},
    {'code': 'UYU', 'name': 'Uruguayan Peso', 'symbol': '\$'},
    {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': '£'},
    {'code': 'KES', 'name': 'Kenyan Shilling', 'symbol': 'KSh'},
    {'code': 'GHS', 'name': 'Ghanaian Cedi', 'symbol': '₵'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': '₨'},
    {'code': 'BDT', 'name': 'Bangladeshi Taka', 'symbol': '৳'},
    {'code': 'LKR', 'name': 'Sri Lankan Rupee', 'symbol': 'Rs'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
    fromAmountController.addListener(_onFromAmountChanged);
    toAmountController.addListener(_onToAmountChanged);
  }

  @override
  void dispose() {
    fromAmountController.dispose();
    toAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchExchangeRates() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Fetch exchange rates from free API
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = Map<String, dynamic>.from(data['rates']);

        // Convert to Map<String, double>
        Map<String, double> convertedRates = {};
        rates.forEach((key, value) {
          convertedRates[key] = (value as num).toDouble();
        });

        setState(() {
          exchangeRates = convertedRates;
          isLoading = false;
        });

        // Perform initial conversion
        _onFromAmountChanged();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to fetch exchange rates. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
      print('Error fetching exchange rates: $e');
    }
  }

  double _convertCurrency(
      double amount, String fromCurr, String toCurr) {
    if (amount <= 0) return 0;
    if (exchangeRates.isEmpty) return 0;

    final fromRate = exchangeRates[fromCurr] ?? 1.0;
    final toRate = exchangeRates[toCurr] ?? 1.0;

    final converted = (amount / fromRate) * toRate;
    return converted;
  }

  void _onFromAmountChanged() {
    if (fromAmountController.text.isEmpty) return;
    final amount = double.tryParse(fromAmountController.text) ?? 0;
    final converted = _convertCurrency(amount, fromCurrency, toCurrency);
    toAmountController.text = converted.toStringAsFixed(2);
  }

  void _onToAmountChanged() {
    if (toAmountController.text.isEmpty) return;
    final amount = double.tryParse(toAmountController.text) ?? 0;
    final converted = _convertCurrency(amount, toCurrency, fromCurrency);
    fromAmountController.text = converted.toStringAsFixed(2);
  }

  void _swapCurrencies() {
    setState(() {
      final tempCurr = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = tempCurr;

      final tempAmount = fromAmountController.text;
      fromAmountController.text = toAmountController.text;
      toAmountController.text = tempAmount;
    });
  }

  String _getExchangeRate() {
    if (exchangeRates.isEmpty) return 'Loading...';
    final fromRate = exchangeRates[fromCurrency] ?? 1.0;
    final toRate = exchangeRates[toCurrency] ?? 1.0;
    final rate = toRate / fromRate;
    return rate.toStringAsFixed(6);
  }

  List<Map<String, String>> _getFilteredCurrencies(String search) {
    if (search.isEmpty) return currencies;
    return currencies
        .where((curr) =>
            curr['code']!.contains(search.toUpperCase()) ||
            curr['name']!.toLowerCase().contains(search.toLowerCase()))
        .toList();
  }

  void _showCurrencyPicker(
      BuildContext context, bool isFrom) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            String searchQuery = '';
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          isFrom ? 'Select From Currency' : 'Select To Currency',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search currency...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _getFilteredCurrencies(searchQuery).length,
                      itemBuilder: (context, index) {
                        final curr = _getFilteredCurrencies(searchQuery)[index];
                        final isSelected = isFrom
                            ? curr['code'] == fromCurrency
                            : curr['code'] == toCurrency;

                        return InkWell(
                          onTap: () {
                            this.setState(() {
                              if (isFrom) {
                                fromCurrency = curr['code']!;
                              } else {
                                toCurrency = curr['code']!;
                              }
                            });
                            Navigator.pop(context);
                            _onFromAmountChanged();
                          },
                          child: Container(
                            color: isSelected
                                ? Colors.teal.withOpacity(0.1)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      curr['code']!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      curr['name']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  const Icon(Icons.check,
                                      color: Colors.teal),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Converting Currency',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  const Text('Fetching latest exchange rates...'),
                ],
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchExchangeRates,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _showCurrencyPicker(context, true),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal.shade50,
                                          Colors.cyan.shade50,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.teal.shade200,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fromCurrency,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                            Text(
                                              currencies
                                                  .firstWhere(
                                                    (c) =>
                                                        c['code'] ==
                                                        fromCurrency,
                                                  )['name']!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: fromAmountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter amount',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.teal,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade500,
                                Colors.cyan.shade500
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _swapCurrencies,
                              borderRadius: BorderRadius.circular(50),
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(
                                  Icons.arrow_upward,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () =>
                                      _showCurrencyPicker(context, false),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal.shade50,
                                          Colors.cyan.shade50,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.teal.shade200,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              toCurrency,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                            Text(
                                              currencies
                                                  .firstWhere(
                                                    (c) =>
                                                        c['code'] ==
                                                        toCurrency,
                                                  )['name']!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: toAmountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Converted amount',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.teal,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade500,
                                Colors.cyan.shade500
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Exchange Rate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '1 $fromCurrency = ${_getExchangeRate()} $toCurrency',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quick Conversions',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildQuickConversions(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<Widget> _buildQuickConversions() {
    final quickCurrs = ['VND', 'USD', 'EUR', 'GBP', 'JPY'];
    return quickCurrs.map((curr) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: InkWell(
          onTap: () {
            setState(() {
              toCurrency = curr;
            });
            _onFromAmountChanged();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  curr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_convertCurrency(1, fromCurrency, curr).toStringAsFixed(4)} $curr',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}