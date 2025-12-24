import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/api_keys.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String city;
  final String state;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.city,
    required this.state,
  });

  factory PlaceSuggestion.fromNewApiJson(Map<String, dynamic> json) {
    final text = json['text']?['text'] as String? ?? '';
    final structuredFormat = json['structuredFormat'];
    final mainText = structuredFormat?['mainText']?['text'] as String? ?? '';
    final secondaryText = structuredFormat?['secondaryText']?['text'] as String? ?? '';
    
    String city = mainText;
    String state = '';
    
    if (secondaryText.isNotEmpty) {
      final parts = secondaryText.split(',').map((s) => s.trim()).toList();
      if (parts.isNotEmpty) {
        state = parts[0];
      }
    }
    
    return PlaceSuggestion(
      placeId: json['placeId'] as String,
      description: text,
      city: city,
      state: state,
    );
  }
}

class CityAutocompleteField extends StatefulWidget {
  final String? initialCity;
  final String? initialState;
  final Function(String city, String state) onCitySelected;

  const CityAutocompleteField({
    super.key,
    this.initialCity,
    this.initialState,
    required this.onCitySelected,
  });

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _selectedCity;
  String? _selectedState;
  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    _selectedState = widget.initialState;
    
    if (_selectedCity != null && _selectedState != null) {
      _controller.text = '$_selectedCity, $_selectedState';
    }

    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    
    if (_selectedCity != null && _selectedState != null) {
      return;
    }
    
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(_controller.text);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
      
      final requestBody = json.encode({
        'input': query,
        'includedPrimaryTypes': ['(cities)'],
        'languageCode': 'en',
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': ApiKeys.googlePlacesApiKey,
          'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List?;
        
        if (suggestions != null && suggestions.isNotEmpty) {
          setState(() {
            _suggestions = suggestions
                .where((s) => s['placePrediction'] != null)
                .map((s) => PlaceSuggestion.fromNewApiJson(s['placePrediction']))
                .toList();
            _isSearching = false;
          });
        } else {
          setState(() {
            _suggestions = [];
            _isSearching = false;
          });
        }
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = 'API error: ${errorData['error']?['message'] ?? 'Status ${response.statusCode}'}';
          _suggestions = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  void _onPlaceSelected(PlaceSuggestion suggestion) {
    _debounceTimer?.cancel();
    setState(() {
      _selectedCity = suggestion.city;
      _selectedState = suggestion.state;
      _controller.text = '${suggestion.city}, ${suggestion.state}';
      _suggestions = [];
      _errorMessage = null;
      _isSearching = false;
    });
    _focusNode.unfocus();
    widget.onCitySelected(suggestion.city, suggestion.state);
  }

  void _clearSelection() {
    setState(() {
      _controller.clear();
      _selectedCity = null;
      _selectedState = null;
      _suggestions = [];
      _errorMessage = null;
      _isSearching = false;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? const Color(0xFF0039A6)
                      : Colors.grey[300]!,
                  width: _focusNode.hasFocus ? 2 : 1,
                ),
                boxShadow: [
                  if (_focusNode.hasFocus)
                    BoxShadow(
                      color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: _selectedCity == null && _selectedState == null,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Start typing city name...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: const Icon(
                    Icons.location_city,
                    color: Color(0xFF0039A6),
                    size: 22,
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0039A6),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
            ),
            // X button overlay
            if (_controller.text.isNotEmpty && !_isSearching)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    onTap: _clearSelection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red[900],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Suggestions List
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestions.length > 5 ? 5 : _suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return InkWell(
                    onTap: () => _onPlaceSelected(suggestion),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF0039A6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.city,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  suggestion.state,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
