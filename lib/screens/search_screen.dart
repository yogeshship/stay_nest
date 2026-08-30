import 'package:flutter/material.dart';

import '../models/room_model.dart';
import '../services/room_service.dart';
import '../services/saved_rooms_service.dart';
import '../utils/room_discovery.dart';
import '../widgets/room_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialLocation});

  final String? initialLocation;

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;
  late final Stream<List<RoomModel>> _roomsStream;
  late final Stream<Set<String>> _savedRoomIdsStream;
  late RoomDiscoveryCriteria _criteria;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialLocation?.trim() ?? '';
    _searchController = TextEditingController(text: initialQuery);
    _criteria = RoomDiscoveryCriteria(query: initialQuery);
    _roomsStream = RoomService().watchAvailableRooms();
    _savedRoomIdsStream = SavedRoomsService().watchSavedRoomIds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateQuery(String query) {
    setState(() {
      _criteria = RoomDiscoveryCriteria(
        query: query,
        minRent: _criteria.minRent,
        maxRent: _criteria.maxRent,
        genderPreference: _criteria.genderPreference,
        sortOption: _criteria.sortOption,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _criteria = RoomDiscoveryCriteria(
        query: _criteria.query,
        sortOption: _criteria.sortOption,
      );
    });
  }

  void _clearAll() {
    _searchController.clear();
    setState(() => _criteria = const RoomDiscoveryCriteria());
  }

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<RoomDiscoveryCriteria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _RoomFiltersSheet(criteria: _criteria),
    );
    if (result != null && mounted) setState(() => _criteria = result);
  }

  void _setSort(RoomSortOption sortOption) {
    setState(() {
      _criteria = RoomDiscoveryCriteria(
        query: _criteria.query,
        minRent: _criteria.minRent,
        maxRent: _criteria.maxRent,
        genderPreference: _criteria.genderPreference,
        sortOption: sortOption,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchScreen.bgColor,
      appBar: AppBar(
        backgroundColor: SearchScreen.bgColor,
        elevation: 0,
        title: const Text(
          'Search Rooms',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<RoomModel>>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Rooms could not be loaded. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final availableRooms = snapshot.data ?? const <RoomModel>[];
          final results = filterAndSortRooms(availableRooms, _criteria);
          return StreamBuilder<Set<String>>(
            stream: _savedRoomIdsStream,
            builder: (context, savedSnapshot) {
              if (savedSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (savedSnapshot.hasError) {
                return const Center(
                  child: Text('Saved-room status could not be loaded.'),
                );
              }

              final savedRoomIds = savedSnapshot.data ?? const <String>{};
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _updateQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by title or location',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _criteria.hasQuery
                          ? IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                _updateQuery('');
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showFilters,
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(
                            _criteria.activeFilterCount == 0
                                ? 'Filters'
                                : 'Filters (${_criteria.activeFilterCount})',
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _criteria.hasActiveFilters
                                ? const Color(0xFFEDE7FF)
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PopupMenuButton<RoomSortOption>(
                          onSelected: _setSort,
                          itemBuilder: (context) => RoomSortOption.values
                              .map(
                                (option) => PopupMenuItem(
                                  value: option,
                                  child: Text(_sortLabel(option)),
                                ),
                              )
                              .toList(),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFE0D7FF)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sort_rounded, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _sortLabel(_criteria.sortOption),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${results.length} ${results.length == 1 ? 'room' : 'rooms'} found',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_criteria.hasActiveFilters)
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear Filters'),
                        ),
                      if (_criteria.hasQuery ||
                          _criteria.hasActiveFilters ||
                          _criteria.sortOption != RoomSortOption.newest)
                        TextButton(
                          onPressed: _clearAll,
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (availableRooms.isEmpty)
                    const _EmptyResult(
                      message: 'There are currently no rooms available.',
                    )
                  else if (results.isEmpty)
                    _EmptyResult(message: _emptyMessage(_criteria))
                  else
                    ...results.map(
                      (room) => RoomCard(
                        room: room,
                        isSaved: savedRoomIds.contains(room.id),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _RoomFiltersSheet extends StatefulWidget {
  const _RoomFiltersSheet({required this.criteria});

  final RoomDiscoveryCriteria criteria;

  @override
  State<_RoomFiltersSheet> createState() => _RoomFiltersSheetState();
}

class _RoomFiltersSheetState extends State<_RoomFiltersSheet> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  String? _genderPreference;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _minController =
        TextEditingController(text: _numberText(widget.criteria.minRent));
    _maxController =
        TextEditingController(text: _numberText(widget.criteria.maxRent));
    _genderPreference = widget.criteria.genderPreference;
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    try {
      final minRent = parseOptionalRent(_minController.text);
      final maxRent = parseOptionalRent(_maxController.text);
      final rangeError = validateRentRange(minRent, maxRent);
      if (rangeError != null) {
        setState(() => _errorText = rangeError);
        return;
      }
      Navigator.pop(
        context,
        RoomDiscoveryCriteria(
          query: widget.criteria.query,
          minRent: minRent,
          maxRent: maxRent,
          genderPreference: _genderPreference,
          sortOption: widget.criteria.sortOption,
        ),
      );
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter rooms',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Min rent',
                        prefixText: 'Rs. ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Max rent',
                        prefixText: 'Rs. ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _genderPreference ?? 'Any',
                decoration: const InputDecoration(
                  labelText: 'Gender preference',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Any', child: Text('Any preference')),
                  DropdownMenuItem(value: 'Boys', child: Text('Boys')),
                  DropdownMenuItem(value: 'Girls', child: Text('Girls')),
                  DropdownMenuItem(value: 'Family', child: Text('Family')),
                ],
                onChanged: (value) => setState(
                  () => _genderPreference = value == 'Any' ? null : value,
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                      RoomDiscoveryCriteria(
                        query: widget.criteria.query,
                        sortOption: widget.criteria.sortOption,
                      ),
                    ),
                    child: const Text('Clear Filters'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _apply, child: const Text('Apply')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

String _sortLabel(RoomSortOption option) => switch (option) {
      RoomSortOption.newest => 'Newest',
      RoomSortOption.rentLowToHigh => 'Rent: Low to High',
      RoomSortOption.rentHighToLow => 'Rent: High to Low',
    };

String _emptyMessage(RoomDiscoveryCriteria criteria) {
  if (criteria.hasQuery && criteria.hasActiveFilters) {
    return 'No rooms match your search and active filters.';
  }
  if (criteria.hasActiveFilters) return 'No rooms match your active filters.';
  return 'No rooms match your search.';
}

String _numberText(num? value) {
  if (value == null) return '';
  return value is int ? value.toString() : value.toString();
}
