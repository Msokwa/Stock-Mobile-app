import 'package:flutter/material.dart';
import 'package:stock_app/services/location_service.dart';

class Country extends StatefulWidget {
  const Country({super.key});

  @override
  State<Country> createState() => _CountryState();
}

class _CountryState extends State<Country> {
  String _selectedCountry = 'United States';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCountry();
  }

  Future<void> _loadCountry() async {
    final country = await LocationService.getSavedCountry();
    if (!mounted) return;
    setState(() {
      _selectedCountry = country;
      _loading = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    final country = await LocationService.getCurrentCountryName();
    if (!mounted) return;
    await LocationService.saveCountry(country);
    if (!mounted) return;
    setState(() {
      _selectedCountry = country;
    });
    if (!mounted) return;
    Navigator.of(context).pop(country);
  }

  @override
  Widget build(BuildContext context) {
    final countries = <String>[
      'United States',
      'Germany',
      'United Kingdom',
      'India',
      'Canada',
      'France',
      'Japan',
      'Australia',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose country'),
        backgroundColor: const Color(0xFF091625),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my current location'),
                ),
                const SizedBox(height: 16),
                ...countries.map((country) {
                  final isSelected = country == _selectedCountry;
                  return Card(
                    color: isSelected
                        ? Colors.green.shade900
                        : const Color(0xFF091624),
                    child: ListTile(
                      title: Text(country),
                      trailing: Text(LocationService.getFlagEmoji(country)),
                      selected: isSelected,
                      onTap: () async {
                        await LocationService.saveCountry(country);
                        if (!mounted) return;
                        setState(() {
                          _selectedCountry = country;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
