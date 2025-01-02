// process_cubit.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
// process_state.dart
import 'package:equatable/equatable.dart';

class ProcessState extends Equatable {
  final bool isServerRunning;
  final bool isMining;
  final String? cloudflaredUrl;
  final List<String> terminalOutput;
  final bool isCloudflaredInstalled;
  final String miningStatus;
  final double currentBalance;

  const ProcessState({
    this.isServerRunning = false,
    this.isMining = false,
    this.cloudflaredUrl,
    this.terminalOutput = const [],
    this.isCloudflaredInstalled = false,
    this.miningStatus = 'Not mining',
    this.currentBalance = 0.0,
  });

  ProcessState copyWith({
    bool? isServerRunning,
    bool? isMining,
    String? cloudflaredUrl,
    List<String>? terminalOutput,
    bool? isCloudflaredInstalled,
    String? miningStatus,
    double? currentBalance,
  }) {
    return ProcessState(
      isServerRunning: isServerRunning ?? this.isServerRunning,
      isMining: isMining ?? this.isMining,
      cloudflaredUrl: cloudflaredUrl ?? this.cloudflaredUrl,
      terminalOutput: terminalOutput ?? this.terminalOutput,
      isCloudflaredInstalled: isCloudflaredInstalled ?? this.isCloudflaredInstalled,
      miningStatus: miningStatus ?? this.miningStatus,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }

  @override
  List<Object?> get props => [
        isServerRunning,
        isMining,
        cloudflaredUrl,
        terminalOutput,
        isCloudflaredInstalled,
        miningStatus,
        currentBalance,
      ];
}

// Helper class to manage processes
class ProcessManager {
  Process? process;
  final String name;
  final void Function(String) onOutput;
  final void Function(String) onError;
  final void Function()? onExit;

  ProcessManager({
    required this.name,
    required this.onOutput,
    required this.onError,
    this.onExit,
  });
Future<void> start({
  required String executable,
  required List<String> arguments,
  int port = 5000, // Default server port
}) async {
  try {
    // Check if another process is already using the port
    await _terminateProcessesOnPort(port);

    // Start process without detached mode for better control
    process = await Process.start(
      executable,
      arguments,
      mode: ProcessStartMode.normal, // Changed from detachedWithStdio
      runInShell: true,
    );

    // Handle standard output
    process!.stdout.transform(utf8.decoder).listen(
      onOutput,
      onDone: () {
        onExit?.call();
        process = null;
      },
      onError: (error) {
        onError('Process error: $error');
        process = null;
      },
    );

    // Handle standard error
    process!.stderr.transform(utf8.decoder).listen(
      onError,
      onError: (error) {
        onError('Process error: $error');
      },
    );
  } catch (e) {
    onError('Failed to start process: $e');
    rethrow;
  }
}

// Utility function to terminate processes on a specific port
Future<void> _terminateProcessesOnPort(int port) async {
  try {
    // Platform-specific handling for port termination
    if (Platform.isWindows) {
      // Use `netstat` and `taskkill` on Windows
      final result = await Process.run('netstat', ['-ano']);
      final lines = result.stdout.toString().split('\n');
      final matchingLines = lines.where((line) => line.contains(':$port'));

      for (final line in matchingLines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length > 4) {
          final pid = parts[4]; // Extract PID
          await Process.run('taskkill', ['/PID', pid, '/F']);
          onOutput('🛑 Terminated process with PID: $pid on port $port');
        }
      }
    } else {
      // Use `lsof` and `kill` on Unix-based systems
      final result = await Process.run('lsof', ['-i:$port']);
      final output = result.stdout.toString();

      // Extract process IDs (PIDs) from the lsof command output
      final pids = RegExp(r'\b\d+\b')
          .allMatches(output)
          .map((match) => match.group(0))
          .whereType<String>();

      for (final pid in pids) {
        await Process.run('kill', ['-9', pid]);
        onOutput('🛑 Terminated process with PID: $pid on port $port');
      }
    }
  } catch (e) {
    onError('⚠️ Failed to terminate processes on port $port: $e');
  }
}


  Future<void> stop() async {
    if (process != null) {
      try {
        // Try graceful shutdown first
        process!.kill(ProcessSignal.sigterm);
        
        // Wait for process to exit with timeout
        await process!.exitCode.timeout(
          Duration(seconds: 5),
          onTimeout: () {
            // Force kill if graceful shutdown fails
            process!.kill(ProcessSignal.sigkill);
            return -1;
          },
        );

        _terminateProcessesOnPort(5000);
      } catch (e) {
        onError('Error stopping process: $e');
      } finally {
        process = null;
      }
    }
  }

  bool get isRunning => process != null;
}
class ProcessCubit extends Cubit<ProcessState> {
  ProcessManager? _serverManager;
  ProcessManager? _tunnelManager;
  Timer? _balanceUpdateTimer;
  
  ProcessCubit() : super(const ProcessState()) {
    _loadPersistedState();
    _startBalanceUpdates();
  }

  Future<void> _loadPersistedState() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/mining_state.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(jsonString);
        
        emit(ProcessState(
          terminalOutput: List<String>.from(json['terminalOutput'] ?? []),
          cloudflaredUrl: json['cloudflaredUrl'],
          isCloudflaredInstalled: json['isCloudflaredInstalled'] ?? false,
          currentBalance: json['currentBalance'] ?? 0.0,
        ));
      }
    } catch (e) {
      addToTerminal('Error loading persisted state: $e');
    }
  }

  Future<void> _persistState() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/mining_state.json');
      
      await file.writeAsString(jsonEncode({
        'terminalOutput': state.terminalOutput,
        'cloudflaredUrl': state.cloudflaredUrl,
        'isCloudflaredInstalled': state.isCloudflaredInstalled,
        'currentBalance': state.currentBalance,
      }));
    } catch (e) {
      addToTerminal('Error persisting state: $e');
    }
  }

  void _startBalanceUpdates() {
    _balanceUpdateTimer?.cancel();
    _balanceUpdateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (state.isMining) {
        // Simulate mining rewards
        emit(state.copyWith(
          currentBalance: state.currentBalance + 0.01,
        ));
        _persistState();
      }
    });
  }

  void addToTerminal(String message) {
    final updatedOutput = [...state.terminalOutput, message];
    if (updatedOutput.length > 1000) {
      updatedOutput.removeAt(0);
    }
    emit(state.copyWith(terminalOutput: updatedOutput));
    _persistState();
  }

  Future<void> checkCloudflared() async {
    try {
      addToTerminal('Checking Cloudflared installation...');
      final result = await Process.run('cloudflared', ['--version'],
          runInShell: true, // Add this for Windows compatibility
      );
      
      final isInstalled = result.exitCode == 0;
      emit(state.copyWith(isCloudflaredInstalled: isInstalled));
      
      addToTerminal(isInstalled 
        ? '✅ Cloudflared is installed: ${result.stdout}'
        : '❌ Cloudflared is not installed. Please install it first.');
        
      if (!isInstalled) {
        addToTerminal('''
📝 To install Cloudflared:
1. Windows: Download from https://github.com/cloudflare/cloudflared/releases
2. Mac: brew install cloudflare/cloudflare/cloudflared
3. Linux: curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
''');
      }
    } catch (e) {
      emit(state.copyWith(isCloudflaredInstalled: false));
      addToTerminal('❌ Error checking Cloudflared: $e');
    }
    _persistState();
  }

// Modified server process functions
Future<ProcessManager> createServerProcess(
  String url,
  void Function(String) onOutput,
  void Function(String) onError,
  void Function()? onExit,
) async {
  final manager = ProcessManager(
    name: 'Server',
    onOutput: onOutput,
    onError: onError,
    onExit: onExit,
  );
    print('Installing dependencies...');
    await Process.start(
      'python',
      ['-m', 'pip', 'install', 'pybase64', 'Flask', 'Flask-Cors', 'requests', 'schedule', 'ecdsa', 'firebase-admin', 'base58', 'starkbank-ecdsa', 'elliptic-curve', 'Flask-CORS'],
      mode: ProcessStartMode.detachedWithStdio,
      runInShell: true, // Run in shell mode to handle multiple arguments properly
    );

    print('Dependencies installed successfully.');

  await manager.start(
    executable: 'python',
    arguments: ['./server/app.py', '--url', url],
  );
  
  return manager;
}

Future<ProcessManager> createTunnelProcess(
  void Function(String) onOutput,
  void Function(String) onError,
  void Function()? onExit,
) async {
  final manager = ProcessManager(
    name: 'Cloudflared',
    onOutput: onOutput,
    onError: onError,
    onExit: onExit,
  );
  
  await manager.start(
    executable: 'cloudflared',
    arguments: ['tunnel', '--url', 'http://localhost:5000'],
  );
  
  return manager;
}

  Future<void> startServer(String url) async {
    if (state.isServerRunning) {
      addToTerminal('⚠️ Server is already running');
      return;
    }

    try {
      addToTerminal('🚀 Starting server...');
      _serverManager = await createServerProcess(
        url,
        (data) => addToTerminal('📤 Server: $data'),
        (error) => addToTerminal('⚠️ Server Error: $error'),
        () {
          emit(state.copyWith(isServerRunning: false));
          addToTerminal('🔄 Server process ended');
        },
      );
      
      emit(state.copyWith(isServerRunning: true));
      addToTerminal('✅ Server started successfully');
    } catch (e) {
      emit(state.copyWith(isServerRunning: false));
      addToTerminal('❌ Error starting server: $e');
    }
  }

  Future<void> startMining() async {
    if (!state.isCloudflaredInstalled) {
      addToTerminal('⚠️ Please install Cloudflared first');
      return;
    }

    if (state.isMining) {
      addToTerminal('⚠️ Mining is already in progress');
      return;
    }

    try {
      addToTerminal('🚀 Starting Cloudflared tunnel...');
      _tunnelManager = await createTunnelProcess(
        (data) {
          handleCloudflareUrl(data);
          addToTerminal('📤 Cloudflared: $data');
        },
        (error) {
          if (error.contains('cloudflared.exe')) {
            addToTerminal('⚠️ Cloudflared Error: Please ensure Cloudflared is in your system PATH');
          } else {
            addToTerminal('⚠️ Cloudflared Error: $error');
          }
        },
        () {
          emit(state.copyWith(isMining: false));
          addToTerminal('🔄 Cloudflared process ended');
        },
      );

      emit(state.copyWith(
        isMining: true,
        miningStatus: 'Mining in progress',
      ));
      
      addToTerminal('✅ Mining started successfully');
    } catch (e) {
      emit(state.copyWith(isMining: false));
      addToTerminal('❌ Error starting mining: $e');
    }
  }
void clearTerminal() {
  emit(state.copyWith(
    terminalOutput: [],
    cloudflaredUrl: null,
  ));
  _persistState();
}
  void handleCloudflareUrl(String output) {
    final RegExp urlRegex = RegExp(
      r'https?\s*:?\s*//\s*[-a-zA-Z0-9]+(?:\s*\.\s*trycloudflare\s*\.\s*com\b)',
      caseSensitive: false,
      multiLine: true,
    );
    
    try {
      final matches = urlRegex.allMatches(output);
      
      for (final match in matches) {
        final rawUrl = match.group(0);
        
        if (rawUrl != null) {
          final cleanUrl = rawUrl
              .replaceAll(RegExp(r'\s+'), '')
              .replaceAll(RegExp(r':{2,}'), ':')
              .toLowerCase();
          
          if (cleanUrl.contains('trycloudflare.com') && 
              cleanUrl.startsWith('http') &&
              cleanUrl != state.cloudflaredUrl) {
            
            emit(state.copyWith(cloudflaredUrl: cleanUrl));
            addToTerminal('📋 New Cloudflare URL detected: $cleanUrl');
            break;
          }
        }
      }
    } catch (e) {
      addToTerminal('⚠️ Error processing Cloudflare URL: $e');
    }
  }

  Future<void> stopServer() async {
    if (!state.isServerRunning || _serverManager == null) {
      addToTerminal('⚠️ Server is not running');
      return;
    }

    try {
      addToTerminal('🛑 Stopping server...');
      await _serverManager!.stop();
      _serverManager = null;
      
      emit(state.copyWith(isServerRunning: false));
      addToTerminal('✅ Server stopped successfully');
    } catch (e) {
      addToTerminal('⚠️ Error stopping server: $e');
    }
  }

  Future<void> stopMining() async {
    if (!state.isMining) {
      addToTerminal('⚠️ Mining is not running');
      return;
    }

    try {
      addToTerminal('🛑 Stopping mining...');
      
      if (_tunnelManager != null) {
        await _tunnelManager!.stop();
        _tunnelManager = null;
      }
      
      emit(state.copyWith(
        isMining: false,
        miningStatus: 'Mining stopped',
        cloudflaredUrl: null,
      ));
      
      addToTerminal('✅ Mining stopped successfully');
    } catch (e) {
      addToTerminal('⚠️ Error stopping mining: $e');
    }
  }

  @override
  Future<void> close() {
    _balanceUpdateTimer?.cancel();
    stopServer();
    stopMining();
    return super.close();
  }
}