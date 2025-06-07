import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:taskova_shopkeeper/language/language_provider.dart';

class PostcodeSearchWidget extends StatefulWidget {
  final Function(double latitude, double longitude, String address)
  onAddressSelected;
  final String placeholderText;
  final TextEditingController? postcodeController;

  const PostcodeSearchWidget({
    super.key,
    required this.onAddressSelected,
    this.placeholderText = 'Enter postcode',
    this.postcodeController,
  });

  @override
  _PostcodeSearchWidgetState createState() => _PostcodeSearchWidgetState();
}

class _PostcodeSearchWidgetState extends State<PostcodeSearchWidget> {
  late TextEditingController _postcodeController;
  bool _isSearching = false;
  List<Map<String, dynamic>> _addressSuggestions = [];
  Timer? _debounceTimer;
  late AppLanguage appLanguage;
  bool _isUpdatingProgrammatically = false;

  // Define color scheme
  final Color primaryBlue = const Color(0xFF1A5DC1);
  final Color lightBlue = const Color(0xFFE6F0FF);
  final Color accentBlue = const Color(0xFF0E4DA4);
  final Color whiteColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _postcodeController = widget.postcodeController ?? TextEditingController();
    _postcodeController.addListener(_onPostcodeChanged);
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
  }

  @override
  void dispose() {
    _postcodeController.removeListener(_onPostcodeChanged);
    if (widget.postcodeController == null) {
      _postcodeController.dispose();
    }
    _debounceTimer?.cancel();
    _isUpdatingProgrammatically = false; // Reset flag on dispose
    super.dispose();
  }

  void _onPostcodeChanged() {
    // Don't trigger search if we're updating the field programmatically
    if (_isUpdatingProgrammatically) {
      return;
    }

    if (_postcodeController.text.length >= 3) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _fetchAddressSuggestions(_postcodeController.text);
      });
    } else {
      setState(() {
        _addressSuggestions = [];
      });
    }
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _addressSuggestions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<Location> locations = await locationFromAddress('$query, UK');
      List<Map<String, dynamic>> suggestions = [];

      for (var location in locations) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        for (var placemark in placemarks) {
          String address = _formatAddress(placemark);
          if (address.isNotEmpty) {
            suggestions.add({
              'address': address,
              'latitude': location.latitude,
              'longitude': location.longitude,
              'postcode':
                  placemark.postalCode ?? '', // Store individual postcode
            });
          }
        }
      }

      setState(() {
        _addressSuggestions = suggestions;
      });

      if (suggestions.isEmpty) {
        _showErrorDialog(
          appLanguage.get('no_results_found') ??
              'No addresses found for this postcode',
        );
      }
    } catch (e) {
      _showErrorDialog(
        appLanguage.get('error_fetching_suggestions') ??
            'Error fetching suggestions: $e',
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  String _formatAddress(Placemark placemark) {
    List<String> addressParts = [
      placemark.street ??
          '', // Includes house number, e.g., "10 Downing Street"
      placemark.locality ?? '',
      placemark.subAdministrativeArea ?? '',
      placemark.administrativeArea ?? '',
      placemark.postalCode ?? '',
      placemark.country ?? '',
    ];
    return addressParts.where((part) => part.isNotEmpty).join(', ');
  }

  void _selectAddress(Map<String, dynamic> suggestion) {
    // Set flag to prevent triggering search when updating postcode
    _isUpdatingProgrammatically = true;

    // Update the postcode field with the full postcode from the selected address
    String fullPostcode = suggestion['postcode'] ?? '';
    if (fullPostcode.isNotEmpty) {
      _postcodeController.text = fullPostcode;
    }

    setState(() {
      _addressSuggestions = []; // Clear suggestions
    });

    // Reset flag after a brief delay to allow the field update to complete
    Future.delayed(const Duration(milliseconds: 100), () {
      _isUpdatingProgrammatically = false;
    });

    widget.onAddressSelected(
      suggestion['latitude'],
      suggestion['longitude'],
      suggestion['address'],
    );
  }

  Future<void> _searchByPostcode(String postcode) async {
    if (postcode.isEmpty) {
      _showErrorDialog(
        appLanguage.get('postcode_empty') ?? 'Please enter a postcode',
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _addressSuggestions = [];
    });

    try {
      List<Location> locations = await locationFromAddress('$postcode, UK');
      List<Map<String, dynamic>> allAddresses = [];

      for (var location in locations) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        for (var placemark in placemarks) {
          String address = _formatAddress(placemark);
          if (address.isNotEmpty) {
            allAddresses.add({
              'address': address,
              'latitude': location.latitude,
              'longitude': location.longitude,
              'postcode': placemark.postalCode ?? '',
            });
          }
        }
      }

      if (allAddresses.isNotEmpty) {
        setState(() {
          _addressSuggestions = allAddresses;
        });
        if (allAddresses.length == 1) {
          _selectAddress(allAddresses[0]); // Auto-select if only one result
        }
      } else {
        _showErrorDialog(
          appLanguage.get('no_results_found') ??
              'No addresses found for this postcode',
        );
      }
    } catch (e) {
      _showErrorDialog(
        appLanguage.get('error_searching_postcode') ??
            'Error searching postcode: $e',
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(appLanguage.get('error') ?? 'Error'),
            content: Text(message),
            actions: [
              TextButton(
                child: Text(appLanguage.get('ok') ?? 'OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _postcodeController,
                decoration: InputDecoration(
                  labelText: widget.placeholderText,
                  hintText: widget.placeholderText,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE6F0FF),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1A5DC1),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _searchByPostcode(_postcodeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
              ),
              child: Text(appLanguage.get('search') ?? 'Search'),
            ),
          ],
        ),
        if (_addressSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryBlue.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _addressSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _addressSuggestions[index];
                return ListTile(
                  title: Text(
                    suggestion['address'],
                    style: const TextStyle(color: Color(0xFF0E4DA4)),
                  ),
                  subtitle: Text(
                    'Postcode: ${suggestion['postcode']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  onTap: () => _selectAddress(suggestion),
                );
              },
            ),
          ),
        if (_isSearching)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(color: Color(0xFF1A5DC1)),
            ),
          ),
      ],
    );
  }
}
