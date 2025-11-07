// //cpr_training_app/lib/main.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import 'providers/config_provider.dart';
// import 'providers/session_provider.dart';
// import 'providers/metrics_provider.dart';
// import 'providers/alerts_provider.dart';
// import 'providers/graph_provider.dart';
// import 'providers/sync_provider.dart';
// import 'providers/replay_provider.dart';
// import 'services/db_service.dart';
// import 'services/sensor_service.dart';
// import 'services/processing_engine.dart';
// import 'services/audio_service.dart';
// import 'services/voice_service.dart';
// import 'services/sync_service.dart';
// import 'screens/dashboard_screen.dart' ;
// import 'screens/system_config_screen.dart';
// import 'screens/cloud_config_screen.dart';
// import 'screens/data_viewer_screen.dart';
// import 'screens/replay_screen.dart';
// import 'screens/debrief_screen.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialize database
//   await DBService.instance.initialize();
//
//   // Initialize audio service
//   await AudioService.instance.initialize();
//
//   // Initialize voice service
//   await VoiceService.instance.initialize();
//
//   runApp(const CPRTrainingApp());
// }
//
// class CPRTrainingApp extends StatelessWidget {
//   const CPRTrainingApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ConfigProvider()),
//         ChangeNotifierProvider(create: (_) => SessionProvider()),
//         ChangeNotifierProvider(create: (_) => MetricsProvider()),
//         ChangeNotifierProvider(create: (_) => AlertsProvider()),
//         ChangeNotifierProvider(create: (_) => GraphProvider()),
//         ChangeNotifierProvider(create: (_) => SyncProvider()),
//         ChangeNotifierProvider(create: (_) => ReplayProvider()),
//         Provider(create: (_) => SensorService()),
//         Provider(create: (_) => ProcessingEngine()),
//         Provider(create: (_) => AudioService.instance),
//         Provider(create: (_) => VoiceService.instance),
//         Provider(create: (_) => SyncService.instance),
//       ],
//       child: MaterialApp(
//         title: 'CPR Training System',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           useMaterial3: true,
//           colorScheme: ColorScheme.fromSeed(
//             seedColor: const Color(0xFF2E7D32),
//             brightness: Brightness.light,
//           ),
//           appBarTheme: const AppBarTheme(
//             centerTitle: true,
//             elevation: 0,
//             scrolledUnderElevation: 0,
//           ),
//           cardTheme: CardThemeData(
//             // ÃƒÆ’Ã‚Â¢Ãƒâ€¦"ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ FIXED
//             elevation: 8,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//           ),
//           elevatedButtonTheme: ElevatedButtonThemeData(
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ),
//         initialRoute: '/',
//         routes: {
//           '/': (context) => const CPRMainScreen(),
//           '/dashboard': (context) => const DashboardScreen(),
//           '/system-config': (context) => const SystemConfigScreen(),
//           '/cloud-config': (context) => const CloudConfigScreen(),
//           '/data-viewer': (context) => const DataViewerScreen(),
//           '/replay': (context) => const ReplayScreen(),
//           '/debrief': (context) => const DebriefScreen(),
//         },
//       ),
//     );
//   }
// }
//
// class CPRMainScreen extends StatefulWidget {
//   const CPRMainScreen({super.key});
//
//   @override
//   State<CPRMainScreen> createState() => _CPRMainScreenState();
// }
//
// class _CPRMainScreenState extends State<CPRMainScreen> {
//   int _selectedIndex = 0;
//
//   final List<Widget> _screens = [
//     const DashboardScreen(),
//     const SystemConfigScreen(),
//     const CloudConfigScreen(),
//     const DataViewerScreen(),
//     const ReplayScreen(),
//   ];
//
//   final List<String> _titles = [
//     'CPR Dashboard',
//     'System Config',
//     'Cloud Config',
//     'Data Viewer',
//     'Session Replay',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }
//
//   Future<void> _initializeApp() async {
//     // Request permissions
//     await _requestPermissions();
//
//     // Initialize Bluetooth
//     await _initializeBluetooth();
//
//     // Load configurations
//     if (mounted) {
//       await context.read<ConfigProvider>().loadConfigurations();
//       if (mounted) {
//         final config = context.read<ConfigProvider>().systemConfig;
//         context.read<MetricsProvider>().initialize(config);
//       }
//     }
//   }
//
//   Future<void> _requestPermissions() async {
//     await [
//       Permission.bluetooth,
//       Permission.bluetoothConnect,
//       Permission.bluetoothScan,
//       Permission.bluetoothAdvertise,
//       Permission.location,
//       Permission.microphone,
//       Permission.storage,
//       Permission.manageExternalStorage,
//     ].request();
//   }
//
//   Future<void> _initializeBluetooth() async {
//     if (await FlutterBluePlus.isSupported == false) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Bluetooth not supported on this device'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       return;
//     }
//
//     // Listen to Bluetooth state changes
//     FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
//       if (mounted) {
//         switch (state) {
//           case BluetoothAdapterState.off:
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Please turn on Bluetooth'),
//                 backgroundColor: Colors.orange,
//               ),
//             );
//             break;
//           case BluetoothAdapterState.on:
//             // Bluetooth is ready
//             break;
//           default:
//             break;
//         }
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_titles[_selectedIndex]),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         foregroundColor: Theme.of(context).colorScheme.onPrimary,
//         actions: [
//           Consumer<SessionProvider>(
//             builder: (context, sessionProvider, child) {
//               return Container(
//                 margin: const EdgeInsets.only(right: 16),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: sessionProvider.isSessionActive
//                       ? Colors.red
//                       : Colors.green,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       sessionProvider.isSessionActive
//                           ? Icons.stop
//                           : Icons.play_arrow,
//                       size: 16,
//                       color: Colors.white,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       sessionProvider.isSessionActive ? 'ACTIVE' : 'IDLE',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Consumer<SyncProvider>(
//         builder: (context, syncProvider, child) {
//           return Stack(
//             children: [
//               _screens[_selectedIndex],
//               if (syncProvider.isSyncing)
//                 Container(
//                   color: Colors.black54,
//                   child: const Center(
//                     child: Card(
//                       child: Padding(
//                         padding: EdgeInsets.all(24.0),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             CircularProgressIndicator(),
//                             SizedBox(height: 16),
//                             Text(
//                               'Syncing data - no operations allowed',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           );
//         },
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         selectedItemColor: Theme.of(context).colorScheme.primary,
//         unselectedItemColor: Theme.of(context)
//             .colorScheme
//             .onSurface
//             .withValues(alpha: 0.6), // ÃƒÆ’Ã‚Â¢Ãƒâ€¦"ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ FIXED
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'System'),
//           BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Cloud'),
//           BottomNavigationBarItem(icon: Icon(Icons.data_usage), label: 'Data'),
//           BottomNavigationBarItem(icon: Icon(Icons.replay), label: 'Replay'),
//         ],
//       ),
//       floatingActionButton: _selectedIndex == 0
//           ? FloatingActionButton.extended(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/debrief');
//               },
//               icon: const Icon(Icons.assessment),
//               label: const Text('Debrief'),
//               backgroundColor: Theme.of(context).colorScheme.secondary,
//             )
//           : null,
//     );
//   }
// }

//cpr_training_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'providers/config_provider.dart';
import 'providers/session_provider.dart';
import 'providers/metrics_provider.dart';
import 'providers/alerts_provider.dart';
import 'providers/graph_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/replay_provider.dart';
import 'services/db_service.dart';
import 'services/sensor_service.dart';
import 'services/processing_engine.dart';
import 'services/audio_service.dart';
import 'services/voice_service.dart';
import 'services/sync_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/system_config_screen.dart';
import 'screens/cloud_config_screen.dart';
import 'screens/data_viewer_screen.dart';
import 'screens/replay_screen.dart';
import 'screens/debrief_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DBService.instance.initialize();

  // Initialize audio service
  await AudioService.instance.initialize();

  // Initialize voice service
  await VoiceService.instance.initialize();

  runApp(const CPRTrainingApp());
}

class CPRTrainingApp extends StatelessWidget {
  const CPRTrainingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => MetricsProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
        ChangeNotifierProvider(create: (_) => GraphProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => ReplayProvider()),
        Provider(create: (_) => SensorService()),
        Provider(create: (_) => ProcessingEngine()),
        Provider(create: (_) => AudioService.instance),
        Provider(create: (_) => VoiceService.instance),
        Provider(create: (_) => SyncService.instance),
      ],
      child: MaterialApp(
        title: 'CPR Training System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          cardTheme: CardThemeData(
            // ÃƒÆ’Ã‚Â¢Ãƒâ€¦"ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ FIXED
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const CPRMainScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/system-config': (context) => const SystemConfigScreen(),
          '/cloud-config': (context) => const CloudConfigScreen(),
          '/data-viewer': (context) => const DataViewerScreen(),
          '/replay': (context) => const ReplayScreen(),
          '/debrief': (context) => const DebriefScreen(),
        },
      ),
    );
  }
}

class CPRMainScreen extends StatefulWidget {
  const CPRMainScreen({super.key});

  @override
  State<CPRMainScreen> createState() => _CPRMainScreenState();
}

class _CPRMainScreenState extends State<CPRMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SystemConfigScreen(),
    const CloudConfigScreen(),
    const DataViewerScreen(),
    const ReplayScreen(),
  ];

  final List<String> _titles = [
    'CPR Dashboard',
    'System Config',
    'Cloud Config',
    'Data Viewer',
    'Session Replay',
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Request permissions
    await _requestPermissions();

    // Initialize Bluetooth
    await _initializeBluetooth();

    // Load configurations
    if (mounted) {
      await context.read<ConfigProvider>().loadConfigurations();
      if (mounted) {
        final config = context.read<ConfigProvider>().systemConfig;
        context.read<MetricsProvider>().initialize(config);
      }
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.microphone,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();
  }

  Future<void> _initializeBluetooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth not supported on this device'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Listen to Bluetooth state changes
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (mounted) {
        switch (state) {
          case BluetoothAdapterState.off:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please turn on Bluetooth'),
                backgroundColor: Colors.orange,
              ),
            );
            break;
          case BluetoothAdapterState.on:
          // Bluetooth is ready
            break;
          default:
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sessionProvider.isSessionActive
                      ? Colors.red
                      : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sessionProvider.isSessionActive
                          ? Icons.stop
                          : Icons.play_arrow,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sessionProvider.isSessionActive ? 'ACTIVE' : 'IDLE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SyncProvider>(
        builder: (context, syncProvider, child) {
          return Stack(
            children: [
              _screens[_selectedIndex],
              if (syncProvider.isSyncing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Syncing data - no operations allowed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.6), // ÃƒÆ’Ã‚Â¢Ãƒâ€¦"ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ FIXED
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'System'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Cloud'),
          BottomNavigationBarItem(icon: Icon(Icons.data_usage), label: 'Data'),
          BottomNavigationBarItem(icon: Icon(Icons.replay), label: 'Replay'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/debrief');
        },
        icon: const Icon(Icons.assessment),
        label: const Text('Debrief'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      )
          : null,
    );
  }
}