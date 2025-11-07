//cpr_training_app/lib/screens/data_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../services/db_service.dart';
import '../models/models.dart';

enum TableType {
  sessions,
  samples,
  events,
  configs,
  keyValue,
}

class DataViewerScreen extends StatefulWidget {
  const DataViewerScreen({super.key});

  @override
  State<DataViewerScreen> createState() => _DataViewerScreenState();
}

class _DataViewerScreenState extends State<DataViewerScreen> {
  TableType _selectedTable = TableType.sessions;
  bool _isLoading = true;
  bool _isExporting = false;
  DatabaseStatistics? _dbStats;

  // Data for different tables
  List<CPRSession> _sessions = [];
  List<SensorSample> _samples = [];
  List<CPREvent> _events = [];
  List<Map<String, dynamic>> _configs = [];
  List<Map<String, dynamic>> _keyValues = [];

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 20;

  // Search
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await DBService.instance.getDatabaseStatistics();
      setState(() {
        _dbStats = stats;
      });

      await _loadTableData();
    } catch (e) {
      _showErrorDialog('Load Error', e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTableData() async {
    switch (_selectedTable) {
      case TableType.sessions:
        final sessions = await DBService.instance.getAllSessions();
        setState(() {
          _sessions = sessions;
        });
        break;
      case TableType.samples:
        final samples = await _getAllSamples();
        setState(() {
          _samples = samples;
        });
        break;
      case TableType.events:
        final events = await _getAllEvents();
        setState(() {
          _events = events;
        });
        break;
      case TableType.configs:
        final configs = await _getAllConfigs();
        setState(() {
          _configs = configs;
        });
        break;
      case TableType.keyValue:
        final keyValues = await _getAllKeyValues();
        setState(() {
          _keyValues = keyValues;
        });
        break;
    }

    setState(() {
      _currentPage = 0;
    });
  }

  Future<List<SensorSample>> _getAllSamples() async {
    final db = DBService.instance.database;

    // Make sure we're selecting all the columns including the raw data
    final results = await db.query('samples',
        columns: [
          'id',
          'session_id',
          'ts_ms',
          's1_raw',
          's2_raw',
          's1_avg',
          's2_avg'
        ],
        orderBy: 'ts_ms DESC',
        limit: 1000);

    return results.map((row) {
      return SensorSample(
        id: row['id'] as int,
        sessionId: row['session_id'] as int,
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['ts_ms'] as int),
        sensor1Raw: row['s1_raw'] as int, // This should now get the raw value
        sensor2Raw: row['s2_raw'] as int, // This should now get the raw value
        sensor1Avg: row['s1_avg'] as double,
        sensor2Avg: row['s2_avg'] as double,
      );
    }).toList();
  }

  Future<List<CPREvent>> _getAllEvents() async {
    final db = DBService.instance.database;
    final results =
        await db.query('events', orderBy: 'ts_ms DESC', limit: 1000);
    return results
        .map((row) => CPREvent(
              id: row['id'] as int,
              sessionId: row['session_id'] as int,
              timestamp:
                  DateTime.fromMillisecondsSinceEpoch(row['ts_ms'] as int),
              type: row['type'] as String,
              payload:
                  jsonDecode(row['payload'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getAllConfigs() async {
    final db = DBService.instance.database;
    return await db.query('configs', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> _getAllKeyValues() async {
    final db = DBService.instance.database;
    return await db.query('kv', orderBy: 'key ASC');
  }

  List<dynamic> _getFilteredData() {
    List<dynamic> data;

    switch (_selectedTable) {
      case TableType.sessions:
        data = _sessions;
        break;
      case TableType.samples:
        data = _samples;
        break;
      case TableType.events:
        data = _events;
        break;
      case TableType.configs:
        data = _configs;
        break;
      case TableType.keyValue:
        data = _keyValues;
        break;
    }

    if (_searchQuery.isEmpty) return data;

    return data.where((item) {
      final searchLower = _searchQuery.toLowerCase();
      switch (_selectedTable) {
        case TableType.sessions:
          final session = item as CPRSession;
          return session.sessionNumber.toString().contains(searchLower) ||
              (session.notes?.toLowerCase().contains(searchLower) ?? false);
        case TableType.samples:
          final sample = item as SensorSample;
          return sample.sessionId.toString().contains(searchLower);
        case TableType.events:
          final event = item as CPREvent;
          return event.type.toLowerCase().contains(searchLower) ||
              event.sessionId.toString().contains(searchLower);
        case TableType.configs:
          final config = item as Map<String, dynamic>;
          return (config['name'] as String)
                  .toLowerCase()
                  .contains(searchLower) ||
              (config['kind'] as String).toLowerCase().contains(searchLower);
        case TableType.keyValue:
          final kv = item as Map<String, dynamic>;
          return (kv['key'] as String).toLowerCase().contains(searchLower) ||
              (kv['value'] as String).toLowerCase().contains(searchLower);
      }
    }).toList();
  }

  List<dynamic> _getPaginatedData() {
    final filteredData = _getFilteredData();
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, filteredData.length);
    return filteredData.sublist(startIndex, endIndex);
  }

  int _getTotalPages() {
    final filteredData = _getFilteredData();
    return (filteredData.length / _pageSize).ceil();
  }

  Future<void> _exportToCSV() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final data = _getFilteredData();
      final csvData = _convertToCSV(data);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = '${_selectedTable.name}_export_$timestamp.csv';
      final file = File('${directory.path}/$filename');

      await file.writeAsString(csvData);

      _showSuccessSnackBar('Exported to ${file.path}');
    } catch (e) {
      _showErrorDialog('Export Error', e.toString());
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  String _convertToCSV(List<dynamic> data) {
    if (data.isEmpty) return '';

    List<List<String>> csvRows = [];

    switch (_selectedTable) {
      case TableType.sessions:
        csvRows.add([
          'ID',
          'Session Number',
          'Started At',
          'Ended At',
          'Duration (ms)',
          'Synced',
          'Notes',
          'App Version'
        ]);
        for (final session in data.cast<CPRSession>()) {
          csvRows.add([
            session.id.toString(),
            session.sessionNumber.toString(),
            session.startedAt.toIso8601String(),
            session.endedAt?.toIso8601String() ?? '',
            session.durationMs?.toString() ?? '',
            session.synced.toString(),
            session.notes ?? '',
            session.appVersion,
          ]);
        }
        break;
      case TableType.samples:
        csvRows.add([
          'ID',
          'Session ID',
          'Timestamp',
          'Sensor1 Raw',
          'Sensor2 Raw',
          'Sensor1 Avg',
          'Sensor2 Avg'
        ]);
        for (final sample in data.cast<SensorSample>()) {
          csvRows.add([
            sample.id.toString(),
            sample.sessionId.toString(),
            sample.timestamp.toIso8601String(),
            sample.sensor1Raw.toString(),
            sample.sensor2Raw.toString(),
            sample.sensor1Avg.toString(),
            sample.sensor2Avg.toString(),
          ]);
        }
        break;
      case TableType.events:
        csvRows.add(['ID', 'Session ID', 'Timestamp', 'Type', 'Payload']);
        for (final event in data.cast<CPREvent>()) {
          csvRows.add([
            event.id.toString(),
            event.sessionId.toString(),
            event.timestamp.toIso8601String(),
            event.type,
            jsonEncode(event.payload),
          ]);
        }
        break;
      case TableType.configs:
        csvRows.add(['ID', 'Name', 'Kind', 'JSON', 'Created At']);
        for (final config in data.cast<Map<String, dynamic>>()) {
          csvRows.add([
            config['id'].toString(),
            config['name'].toString(),
            config['kind'].toString(),
            config['json'].toString(),
            DateTime.fromMillisecondsSinceEpoch(config['created_at'] as int)
                .toIso8601String(),
          ]);
        }
        break;
      case TableType.keyValue:
        csvRows.add(['Key', 'Value']);
        for (final kv in data.cast<Map<String, dynamic>>()) {
          csvRows.add([
            kv['key'].toString(),
            kv['value'].toString(),
          ]);
        }
        break;
    }

    return const ListToCsvConverter().convert(csvRows);
  }

  Future<void> _clearEntireDatabase() async {
    final confirmed = await _showConfirmDialog(
      'Clear Database',
      'Delete ALL data? This cannot be undone.',
    );

    if (confirmed) {
      try {
        await DBService.instance.clearAllData();
        await _loadData();
        _showSuccessSnackBar('Database cleared');
      } catch (e) {
        _showErrorDialog('Delete Error', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Compact header
            _buildCompactHeader(),

            // Table selector
            _buildTableSelector(),

            // Search and info row
            _buildSearchRow(),

            // Data table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDataView(),
            ),

            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.data_usage,
              color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Database Viewer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          if (_dbStats != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_dbStats!.databaseSizeMB.toStringAsFixed(2)} MB',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TableType.values.map((type) {
            final isSelected = _selectedTable == type;
            final count = _getTableCount(type);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTableDisplayName(type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTable = type;
                      _searchController.clear();
                      _searchQuery = '';
                    });
                    _loadTableData();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 0;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_getFilteredData().length} rows',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDataView() {
    final paginatedData = _getPaginatedData();

    if (paginatedData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              _getFilteredData().isEmpty ? 'No data' : 'No results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: _buildTableForType(paginatedData),
        ),
      ),
    );
  }

  Widget _buildTableForType(List<dynamic> data) {
    switch (_selectedTable) {
      case TableType.sessions:
        return _buildSessionsTable(data.cast<CPRSession>());
      case TableType.samples:
        return _buildSamplesTable(data.cast<SensorSample>());
      case TableType.events:
        return _buildEventsTable(data.cast<CPREvent>());
      case TableType.configs:
        return _buildConfigsTable(data.cast<Map<String, dynamic>>());
      case TableType.keyValue:
        return _buildKeyValueTable(data.cast<Map<String, dynamic>>());
    }
  }

  Widget _buildSessionsTable(List<CPRSession> sessions) {
    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 12,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 48,
      columns: const [
        DataColumn(
            label: Text('ID',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Session #',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Started',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Duration',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Status',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Notes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
      rows: sessions.map((session) {
        return DataRow(
          cells: [
            DataCell(Text(session.id.toString(),
                style: const TextStyle(fontSize: 11))),
            DataCell(Text(session.sessionNumber.toString(),
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold))),
            DataCell(Text(DateFormat('MMM d HH:mm').format(session.startedAt),
                style: const TextStyle(fontSize: 11))),
            DataCell(Text(
              session.durationMs != null
                  ? _formatDuration(Duration(milliseconds: session.durationMs!))
                  : 'Active',
              style: TextStyle(
                fontSize: 11,
                color: session.durationMs == null ? Colors.green : null,
              ),
            )),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    session.synced ? Icons.cloud_done : Icons.cloud_off,
                    size: 14,
                    color: session.synced ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    session.synced ? 'Synced' : 'Local',
                    style: TextStyle(
                      fontSize: 10,
                      color: session.synced ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              SizedBox(
                width: 100,
                child: Text(
                  session.notes ?? 'No notes',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: session.notes == null ? FontStyle.italic : null,
                    color: session.notes == null
                        ? Theme.of(context).colorScheme.outline
                        : null,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSamplesTable(List<SensorSample> samples) {
    return DataTable(
      columnSpacing: 12,
      horizontalMargin: 12,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 40,
      columns: const [
        DataColumn(
            label: Text('ID',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Session',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Time',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('S1 Raw',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('S2 Raw',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('S1 Avg',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('S2 Avg',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
      rows: samples.map((sample) {
        return DataRow(
          cells: [
            DataCell(Text(sample.id.toString(),
                style: const TextStyle(fontSize: 10))),
            DataCell(Text(sample.sessionId.toString(),
                style: const TextStyle(fontSize: 10))),
            DataCell(Text(DateFormat('HH:mm:ss').format(sample.timestamp),
                style: const TextStyle(fontSize: 10))),
            DataCell(Text(sample.sensor1Raw.toString(),
                style: const TextStyle(fontSize: 10))),
            DataCell(Text(sample.sensor2Raw.toString(),
                style: const TextStyle(fontSize: 10))),
            DataCell(Text(sample.sensor1Avg.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10))),
            DataCell(Text(sample.sensor2Avg.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEventsTable(List<CPREvent> events) {
    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 12,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 48,
      columns: const [
        DataColumn(
            label: Text('ID',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Session',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Time',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Type',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Payload',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
      rows: events.map((event) {
        return DataRow(
          cells: [
            DataCell(Text(event.id.toString(),
                style: const TextStyle(fontSize: 10))),
            DataCell(Text(event.sessionId.toString(),
                style: const TextStyle(fontSize: 10))),
            DataCell(Text(DateFormat('HH:mm:ss').format(event.timestamp),
                style: const TextStyle(fontSize: 10))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.type,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 150,
                child: Text(
                  jsonEncode(event.payload),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildConfigsTable(List<Map<String, dynamic>> configs) {
    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 12,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 48,
      columns: const [
        DataColumn(
            label: Text('ID',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Kind',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Created',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
      rows: configs.map((config) {
        return DataRow(
          cells: [
            DataCell(Text(config['id'].toString(),
                style: const TextStyle(fontSize: 10))),
            DataCell(Text(config['name'].toString(),
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  config['kind'].toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            DataCell(Text(
              DateFormat('MMM d HH:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(
                      config['created_at'] as int)),
              style: const TextStyle(fontSize: 10),
            )),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildKeyValueTable(List<Map<String, dynamic>> keyValues) {
    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 12,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 48,
      columns: const [
        DataColumn(
            label: Text('Key',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Value',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
      rows: keyValues.map((kv) {
        return DataRow(
          cells: [
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  kv['key'].toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 250,
                child: Text(
                  kv['value'].toString(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBottomControls() {
    final totalPages = _getTotalPages();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Pagination
          if (totalPages > 1) ...[
            IconButton(
              onPressed: _currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
              icon: const Icon(Icons.chevron_left, size: 20),
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Text(
              '${_currentPage + 1}/$totalPages',
              style: const TextStyle(fontSize: 12),
            ),
            IconButton(
              onPressed: _currentPage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null,
              icon: const Icon(Icons.chevron_right, size: 20),
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],

          const Spacer(),

          // Action buttons
          TextButton.icon(
            onPressed: _isExporting ? null : _exportToCSV,
            icon: _isExporting
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download, size: 16),
            label: Text(_isExporting ? 'Exporting...' : 'Export',
                style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _clearEntireDatabase,
            icon: const Icon(Icons.delete_forever, size: 16),
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  String _getTableDisplayName(TableType type) {
    switch (type) {
      case TableType.sessions:
        return 'Sessions';
      case TableType.samples:
        return 'Samples';
      case TableType.events:
        return 'Events';
      case TableType.configs:
        return 'Configs';
      case TableType.keyValue:
        return 'Key-Value';
    }
  }

  int _getTableCount(TableType type) {
    if (_dbStats == null) return 0;
    switch (type) {
      case TableType.sessions:
        return _dbStats!.totalSessions;
      case TableType.samples:
        return _dbStats!.totalSamples;
      case TableType.events:
        return _dbStats!.totalEvents;
      case TableType.configs:
        return _dbStats!.totalConfigs;
      case TableType.keyValue:
        return _keyValues.length;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
