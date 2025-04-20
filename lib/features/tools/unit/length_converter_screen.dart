import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LengthConverterScreen extends StatefulWidget {
  const LengthConverterScreen({super.key});

  @override
  State<LengthConverterScreen> createState() => _LengthConverterScreenState();
}

class _LengthConverterScreenState extends State<LengthConverterScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _fromUnit = 'Meter';
  String _toUnit = 'Kilometer';
  double _result = 0;
  bool _hasCalculated = false;

  final Map<String, double> _conversionFactors = {
    'Nanometer': 1e-9,
    'Micrometer': 1e-6,
    'Millimeter': 1e-3,
    'Centimeter': 1e-2,
    'Decimeter': 1e-1,
    'Meter': 1,
    'Kilometer': 1e3,
    'Inch': 0.0254,
    'Foot': 0.3048,
    'Yard': 0.9144,
    'Mile': 1609.344,
    'Nautical Mile': 1852,
  };

  final List<String> _units = [
    'Nanometer',
    'Micrometer',
    'Millimeter',
    'Centimeter',
    'Decimeter',
    'Meter',
    'Kilometer',
    'Inch',
    'Foot',
    'Yard',
    'Mile',
    'Nautical Mile',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    setState(() {
      if (_inputController.text.isEmpty) {
        _hasCalculated = false;
        return;
      }

      try {
        final double inputValue = double.parse(_inputController.text);
        final double fromFactor = _conversionFactors[_fromUnit]!;
        final double toFactor = _conversionFactors[_toUnit]!;
        
        // Convert to base unit (meters) then to target unit
        _result = inputValue * fromFactor / toFactor;
        _hasCalculated = true;
      } catch (e) {
        _hasCalculated = false;
      }
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _convert();
    });
  }

  void _clearInput() {
    setState(() {
      _inputController.clear();
      _hasCalculated = false;
    });
  }

  String _formatResult(double value) {
    if (value == 0) {
      return '0';
    }
    
    if (value.abs() < 0.000001 || value.abs() > 999999) {
      return value.toStringAsExponential(6);
    }
    
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Length Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Enter Value',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearInput,
                        ),
                      ),
                      onChanged: (value) {
                        _convert();
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('From'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _fromUnit,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                ),
                                items: _units.map((String unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _fromUnit = newValue;
                                      _convert();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz),
                            onPressed: _swapUnits,
                            tooltip: 'Swap Units',
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('To'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _toUnit,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                ),
                                items: _units.map((String unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _toUnit = newValue;
                                      _convert();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_hasCalculated) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Result',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_inputController.text} $_fromUnit = ${_formatResult(_result)} $_toUnit',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Conversions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCommonConversion('1 Meter', '100 Centimeters'),
                    _buildCommonConversion('1 Meter', '3.28084 Feet'),
                    _buildCommonConversion('1 Kilometer', '0.621371 Miles'),
                    _buildCommonConversion('1 Inch', '2.54 Centimeters'),
                    _buildCommonConversion('1 Foot', '30.48 Centimeters'),
                    _buildCommonConversion('1 Yard', '0.9144 Meters'),
                    _buildCommonConversion('1 Mile', '1.60934 Kilometers'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonConversion(String from, String to) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            from,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(' = '),
          Text(to),
        ],
      ),
    );
  }
}
