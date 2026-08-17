import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';

class TimeZoneSearchPage extends StatefulWidget {
  const TimeZoneSearchPage({super.key});

  @override
  State<TimeZoneSearchPage> createState() => _TimeZoneSearchPageState();
}

class _TimeZoneSearchPageState extends State<TimeZoneSearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<String> _allTimeZones = [];
  List<String> _filteredTimeZones = [];

  String _systemTzId = '';
  String _systemTzOffset = '';
  bool _isFetchingSystemTz = true;

  late String _tempSelectedTzId;
  late String _tempSelectedTzOffset;
  final double _itemExtentHeight = 52.0;

  final Color _primaryPurple = const Color(0xFF917CEE);
  final Color _textColor = const Color(0xFF333333);
  final Color _bgColor = const Color(0xFFF9F9FC);

  @override
  void initState() {
    super.initState();
    final provider = context.read<ActiveDeviceProvider>();
    _tempSelectedTzId = provider.currentTimeZoneId;
    _tempSelectedTzOffset = provider.currentTimeZoneOffset;

    _allTimeZones = tz.timeZoneDatabase.locations.keys.toList();
    _allTimeZones.sort();
    _filteredTimeZones = _allTimeZones;

    _searchCtrl.addListener(() {
      final query = _searchCtrl.text.toLowerCase();
      setState(() {
        if (query.isEmpty) {
          _filteredTimeZones = _allTimeZones;
        } else {
          _filteredTimeZones = _allTimeZones.where((t) => t.toLowerCase().contains(query)).toList();
        }
      });
    });

    _initSystemTimeZone();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentSelected(isAnimate: false);
    });
  }

  void _scrollToCurrentSelected({bool isAnimate = true}) {
    final index = _filteredTimeZones.indexOf(_tempSelectedTzId);
    if (index == -1 || !_scrollController.hasClients) return;

    final targetOffset = index * _itemExtentHeight;
    if (isAnimate) {
      _scrollController.animateTo(targetOffset, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  Future<void> _initSystemTimeZone() async {
    try {
      final String tzId = await FlutterTimezone.getLocalTimezone();
      final offset = _getOffsetStr(tzId);
      if (mounted) {
        setState(() {
          _systemTzId = tzId;
          _systemTzOffset = offset;
          _isFetchingSystemTz = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isFetchingSystemTz = false);
    }
  }

  String _getOffsetStr(String tzName) {
    try {
      final location = tz.getLocation(tzName);
      final now = tz.TZDateTime.now(location);
      final offset = now.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
      final sign = hours >= 0 ? '+' : '-';
      return 'UTC$sign${hours.abs().toString().padLeft(2, '0')}:$minutes';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final bool isCurrentSelectedInList = _filteredTimeZones.contains(_tempSelectedTzId);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          s.timeZoneTitle,
          style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _bgColor,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(s.cancel, style: const TextStyle(color: Colors.grey)),
        ),
        leadingWidth: 70,
        actions: [
          TextButton(
            onPressed: () {
              context.read<ActiveDeviceProvider>().setTimeZone(_tempSelectedTzId, _tempSelectedTzOffset);
              context.pop();
            },
            child: Text(
              s.confirm,
              style: TextStyle(color: _primaryPurple, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: s.searchTimezoneHint,
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              if (!_isFetchingSystemTz && _systemTzId.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.text = _systemTzId;
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.my_location, size: 18, color: _primaryPurple),
                        const SizedBox(width: 8),
                        Text(
                          s.useSystemTimezone(_systemTzId),
                          style: TextStyle(color: _primaryPurple, fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _filteredTimeZones.length,
                  itemExtent: _itemExtentHeight,
                  itemBuilder: (context, index) {
                    final tzName = _filteredTimeZones[index];
                    final offsetStr = _getOffsetStr(tzName);
                    final isSelected = _tempSelectedTzId == tzName;

                    return ListTile(
                      title: Text(
                        tzName,
                        style: TextStyle(
                          color: isSelected ? _primaryPurple : _textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(offsetStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check, color: _primaryPurple, size: 18),
                          ],
                        ],
                      ),
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          _tempSelectedTzId = tzName;
                          _tempSelectedTzOffset = offsetStr;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isCurrentSelectedInList
          ? FloatingActionButton(
              mini: true,
              backgroundColor: _primaryPurple,
              onPressed: () => _scrollToCurrentSelected(isAnimate: true),
              child: const Icon(Icons.center_focus_strong, color: Colors.white),
            )
          : null,
    );
  }
}
