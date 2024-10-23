import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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
  }) async {
    try {
      // Start process without detached mode for better control
      process = await Process.start(
        executable,
        arguments,
        mode: ProcessStartMode.normal,  // Changed from detachedWithStdio
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
      } catch (e) {
        onError('Error stopping process: $e');
      } finally {
        process = null;
      }
    }
  }

  bool get isRunning => process != null;
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

Future<Process> startServerProcess(String url) async {
  return await Process.start(
    'python',
    ['./server/app.py', '--url', url],
    mode: ProcessStartMode.detachedWithStdio,
    runInShell: true,  // Add this to run in shell mode
  );
}
Future<Process> startTunnelProcess() async {
  // Add runInShell: true to run in a separate shell
  return await Process.start(
    'cloudflared',
    ['tunnel', '--url', 'http://localhost:5000'],
    mode: ProcessStartMode.detachedWithStdio,
    runInShell: true,
  );
}
class MiningDashboard extends StatefulWidget {
  @override
  _MiningDashboardState createState() => _MiningDashboardState();
}

class _MiningDashboardState extends State<MiningDashboard> with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  late TabController _tabController;
  bool _isMining = false;
  String _miningStatus = 'Not mining';
  Process? _tunnelProcess;
  Process? _serverProcess;
  List<String> _terminalOutput = [];
  ScrollController _scrollController = ScrollController();
  bool _isCloudflaredInstalled = false;
  bool _isExpanded = false;
  String? _cloudflaredUrl;
  bool _isServerRunning = false;
ProcessManager? _tunnelManager;
ProcessManager? _serverManager;
  // Add new method for extracting Cloudflared URL
  void _extractCloudflaredUrl(String output) {
    final RegExp urlRegex = RegExp(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com');
    final match = urlRegex.firstMatch(output);
    if (match != null) {
      setState(() {
        _cloudflaredUrl = match.group(0);
      });
      _addToTerminal('📋 Cloudflare URL extracted: $_cloudflaredUrl');
    }
  }
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkCloudflared();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1200) {
            return _buildWideLayout();
          } else if (constraints.maxWidth > 600) {
            return _buildMediumLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          flex: 3,
          child: _buildMainContent(isWide: true),
        ),
      ],
    );
  }

  Widget _buildMediumLayout() {
    return Row(
      children: [
        if (_isExpanded) _buildSidebar(),
        Expanded(
          child: _buildMainContent(isWide: false),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return _buildMainContent(isWide: false);
  }

  Widget _buildSidebar() {
    return Container(
      width: 300,
      color: Color(0xFF1A1A2E),
      child: Column(
        children: [
          _buildLogoHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBalanceCard(),
                    SizedBox(height: 16),
                    _buildStatusCard(),
                    SizedBox(height: 16),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A4A), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
        GestureDetector(
          child: Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onTap: () => Navigator.pop(context),
        ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A4A), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'SMP',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '1,234.56',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.arrow_upward, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text(
                '+2.5% today',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A4A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mining Status',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16),
          _buildStatusRow('Cloudflared', _isCloudflaredInstalled),
          SizedBox(height: 12),
          _buildStatusRow('Server', _serverProcess != null),
          SizedBox(height: 12),
          _buildStatusRow('Mining', _isMining),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.play_arrow,
          label: _isMining ? 'Stop Mining' : 'Start Mining',
          color: _isMining ? Colors.red : Colors.green,
          onPressed: _toggleMining,
        ),
        SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.refresh,
          label: 'Check Cloudflared',
          color: Colors.blue,
          onPressed: _checkCloudflared,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent({required bool isWide}) {
    return Container(
      color: Color(0xFF0F0F1E),
      child: Column(
        children: [
          _buildTopBar(isWide),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isWide) ...[
                    _buildMobileBalanceCard(),
                    SizedBox(height: 24),
                  ],
                  _buildCloudflaredSection(),
                  SizedBox(height: 24),
                  Expanded(child: _buildTerminal()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          Expanded(
            child: Text(
              'Mining Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBalanceCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A4A), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1,234.56 SMP',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.currency_bitcoin,
              color: Colors.orange,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
Widget _buildCloudflaredSection() {
  return Container(
    padding: EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cloudflared Configuration',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _urlController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Paste your Cloudflared URL here',
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.link, color: Colors.white54),
            suffixIcon: IconButton(
              icon: Icon(Icons.paste, color: Colors.white54),
              onPressed: () async {
                ClipboardData? data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  _urlController.text = data!.text!;
                }
              },
            ),
            filled: true,
            fillColor: Color(0xFF2A2A4A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildConfigButton(
                icon: _isServerRunning ? Icons.stop : Icons.play_circle_outline,
                label: _isServerRunning ? 'Stop Server' : 'Start Server',
                color: _isServerRunning ? Colors.red : Colors.green,
                onPressed: _isServerRunning ? _stopServer : _startServer,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildConfigButton(
                icon: Icons.refresh,
                label: 'Check Status',
                color: Colors.blue,
                onPressed: _checkCloudflared,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
Future<void> _stopServer() async {
  if (!_isServerRunning || _serverManager == null) {
    _showSnackBar(
      message: 'Server is not running',
      icon: Icons.info_outline,
      backgroundColor: Colors.blue,
    );
    return;
  }

  try {
    _addToTerminal('🛑 Stopping server...');
    await _serverManager!.stop();
    _serverManager = null;
    
    setState(() {
      _isServerRunning = false;
    });
    
    _addToTerminal('✅ Server stopped successfully');
    _showSnackBar(
      message: 'Server stopped successfully',
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.orange,
    );
  } catch (e) {
    _addToTerminal('⚠️ Error stopping server: $e');
    _showSnackBar(
      message: 'Error stopping server: ${e.toString()}',
      icon: Icons.error_outline,
      backgroundColor: Colors.red,
    );
  }
}
  Widget _buildConfigButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminal() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildTerminalHeader(),
          Expanded(
            child: _buildTerminalContent(),
          ),
        ],
      ),
    );
  }


  // Modify the terminal header to include the Cloudflared URL
  Widget _buildTerminalHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A4A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Row(
                children: [
                  _buildTerminalDot(Colors.red),
                  SizedBox(width: 8),
                  _buildTerminalDot(Colors.yellow),
                  SizedBox(width: 8),
                  _buildTerminalDot(Colors.green),
                ],
              ),
              SizedBox(width: 16),
              Text(
                'Terminal Output',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.copy_all, color: Colors.white70),
                onPressed: _copyTerminalOutput,
                tooltip: 'Copy all',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.white70),
                onPressed: () => setState(() => _terminalOutput.clear()),
                tooltip: 'Clear terminal',
              ),
            ],
          ),
          if (_cloudflaredUrl != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cloudflaredUrl!,
                      style: GoogleFonts.firaCode(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.blue, size: 16),
                    onPressed: _copyCloudflaredUrl,
                    tooltip: 'Copy URL',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTerminalDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTerminalContent() {
    return Container(
      padding: EdgeInsets.all(16),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _terminalOutput.length,
        itemBuilder: (context, index) {
          final output = _terminalOutput[index];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '❯',
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    output,
                    style: GoogleFonts.firaCode(
                      color: _getOutputColor(output),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getOutputColor(String output) {
    if (output.toLowerCase().contains('error')) {
      return Colors.red;
    } else if (output.toLowerCase().contains('success')) {
      return Colors.green;
    } else if (output.toLowerCase().contains('warning')) {
      return Colors.yellow;
    }
    return Colors.white70;
  }

  Future<void> _checkCloudflared() async {
    try {
      _addToTerminal('Checking Cloudflared installation...');
      final result = await Process.run('cloudflared', ['--version']);
      setState(() {
        _isCloudflaredInstalled = result.exitCode == 0;
      });
      _addToTerminal(_isCloudflaredInstalled 
        ? '✅ Cloudflared is installed: ${result.stdout}'
        : '❌ Cloudflared is not installed');
    } catch (e) {
      setState(() {
        _isCloudflaredInstalled = false;
      });
      _addToTerminal('❌ Error checking Cloudflared: $e');
    }
  }
void _addToTerminal(String message) {
  setState(() {
    _terminalOutput.add(message.trim());
    // Keep only the last 1000 lines to prevent memory issues
    if (_terminalOutput.length > 1000) {
      _terminalOutput.removeAt(0);
    }
  });
  
  // Auto-scroll to the bottom after a brief delay to ensure the layout is updated
  Future.delayed(Duration(milliseconds: 50), () {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });
}
  Future<void> _copyTerminalOutput() async {
    final String textToCopy = _terminalOutput.join('\n');
    await Clipboard.setData(ClipboardData(text: textToCopy));
    _showSnackBar(
      message: 'Terminal output copied to clipboard',
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green,
    );
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
  
  Future<void> _startServer() async {
  if (_urlController.text.isEmpty) {
    _showSnackBar(
      message: 'Please paste the Cloudflare URL',
      icon: Icons.error_outline,
      backgroundColor: Colors.red,
    );
    return;
  }

  if (_isServerRunning) {
    _showSnackBar(
      message: 'Server is already running',
      icon: Icons.info_outline,
      backgroundColor: Colors.blue,
    );
    return;
  }

  try {
    _addToTerminal('🚀 Starting server...');
    _serverManager = await createServerProcess(
      _urlController.text,
      (data) => _addToTerminal('📤 Server: $data'),
      (error) => _addToTerminal('⚠️ Server Error: $error'),
      () {
        if (_serverManager != null) {
          setState(() => _isServerRunning = false);
          _addToTerminal('🔄 Server process ended');
        }
      },
    );
    
    setState(() => _isServerRunning = true);
    
    _showSnackBar(
      message: 'Server started successfully',
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green,
    );
  } catch (e) {
    setState(() => _isServerRunning = false);
    _addToTerminal('❌ Error starting server: $e');
    _showSnackBar(
      message: 'Failed to start server: ${e.toString()}',
      icon: Icons.error_outline,
      backgroundColor: Colors.red,
    );
  }
}
  Future<void> _toggleMining() async {
    if (_isMining) {
      _stopMining();
    } else {
      _startMining();
    }
  }

 

 
  // Modified mining start method
Future<void> _startMining() async {
  if (!_isCloudflaredInstalled) {
    _showSnackBar(
      message: 'Please install Cloudflared first',
      icon: Icons.error_outline,
      backgroundColor: Colors.red,
    );
    return;
  }

  if (_isMining) {
    _showSnackBar(
      message: 'Mining is already in progress',
      icon: Icons.info_outline,
      backgroundColor: Colors.blue,
    );
    return;
  }

  try {
    _addToTerminal('🚀 Starting Cloudflared tunnel...');
    _tunnelManager = await createTunnelProcess(
      (data) {
        _addToTerminal('📤 Cloudflared: $data');
        _extractCloudflaredUrl(data);
      },
      (error) => _addToTerminal('⚠️ Cloudflared Error: $error'),
      () {
        setState(() => _isMining = false);
        _addToTerminal('🔄 Cloudflared process ended');
      },
    );

    setState(() {
      _isMining = true;
      _miningStatus = 'Mining in progress';
    });

    _showSnackBar(
      message: 'Mining started successfully',
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green,
    );
  } catch (e) {
    setState(() => _isMining = false);
    _addToTerminal('❌ Error starting mining: $e');
    _showSnackBar(
      message: 'Failed to start mining: ${e.toString()}',
      icon: Icons.error_outline,
      backgroundColor: Colors.red,
    );
  }
}

  // Modified stop method
  Future<void> _stopMining() async {
    _addToTerminal('🛑 Stopping mining processes...');
    
    try {
      if (_tunnelProcess != null) {
        // Send SIGTERM signal for graceful shutdown
        _tunnelProcess!.kill(ProcessSignal.sigterm);
        await _tunnelProcess!.exitCode;
        _tunnelProcess = null;
      }
      
      if (_serverProcess != null) {
        _serverProcess!.kill(ProcessSignal.sigterm);
        await _serverProcess!.exitCode;
        _serverProcess = null;
      }
      
      setState(() {
        _isMining = false;
        _isServerRunning = false;
        _miningStatus = 'Mining stopped';
        _cloudflaredUrl = null;
      });
      
      _addToTerminal('✅ Mining stopped successfully');
      _showSnackBar(
        message: 'Mining stopped successfully',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.orange,
      );
    } catch (e) {
      _addToTerminal('⚠️ Error stopping processes: $e');
      _showSnackBar(
        message: 'Error stopping processes: ${e.toString()}',
        icon: Icons.error_outline,
        backgroundColor: Colors.red,
      );
    }
  }

  // Add new method for copying Cloudflared URL
  void _copyCloudflaredUrl() {
    if (_cloudflaredUrl != null) {
      Clipboard.setData(ClipboardData(text: _cloudflaredUrl!));
      _showSnackBar(
        message: 'Cloudflared URL copied to clipboard',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    }
  }

}


