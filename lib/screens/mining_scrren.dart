import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/blocs/process_bloc.dart';
import 'package:simplicity_coin/blocs/wallet_bloc.dart';



Future<Process> startServerProcess(String url) async {
  try {
    // Install required dependencies using pip
    print('Installing dependencies...');
    await Process.start(
      'python',
      ['-m', 'pip', 'install', 'pybase64', 'Flask', 'Flask-Cors', 'requests', 'schedule', 'ecdsa', 'firebase-admin', 'base58', 'starkbank-ecdsa', 'elliptic-curve', 'Flask-CORS'],
      mode: ProcessStartMode.detachedWithStdio,
      runInShell: true, // Run in shell mode to handle multiple arguments properly
    );

    print('Dependencies installed successfully.');

    // Start the server process
    print('Starting the server...');
    return await Process.start(
      'python',
      ['./server/app.py', '--url', url],
      mode: ProcessStartMode.detachedWithStdio,
      runInShell: true, // Run in shell mode
    );
  } catch (e) {
    print('An error occurred: $e');
    rethrow; // Re-throw the exception to let the caller handle it if needed
  }
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

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(10),
      duration: Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _handleServerToggle(ProcessState state) async {
    if (state.isServerRunning) {
      await context.read<ProcessCubit>().stopServer();
    } else {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        _showSnackBar(
          message: 'Please enter a URL first',
          icon: Icons.error_outline,
          backgroundColor: Colors.red,
        );
        return;
      }
      await context.read<ProcessCubit>().startServer(url);
    }
  }

  Future<void> _handleMiningToggle(ProcessState state) async {
    if (state.isMining) {
      await context.read<ProcessCubit>().stopMining();
    } else {
      if (!state.isCloudflaredInstalled) {
        _showSnackBar(
          message: 'Please install Cloudflared first',
          icon: Icons.error_outline,
          backgroundColor: Colors.red,
        );
        return;
      }
      await context.read<ProcessCubit>().startMining();
    }
  }

  Future<void> _copyTerminalOutput(List<String> output ) async {
    final text = output.join('\n');
 context.read<ProcessCubit>().handleCloudflareUrl(text);

    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(
      message: 'Terminal output copied to clipboard',
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green,
    );
  }

  Future<void> _copyCloudflaredUrl(String? url ) async {
    if (url == null) {
      _showSnackBar(
        message: 'No Cloudflare URL available',
        icon: Icons.error_outline,
        backgroundColor: Colors.red,
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    _showSnackBar(
      message: 'Cloudflare URL copied to clipboard',
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green,
    );
  }


   // Improved URL detection and handling
  void _handleCloudflareUrl(String output) {
    // Print the output for debugging
    print('Analyzing output for URL: $output');
    
    // More comprehensive regex pattern
    final RegExp urlRegex = RegExp(
      r'https?\s*:?\s*//\s*[-a-zA-Z0-9]+(?:\s*\.\s*trycloudflare\s*\.\s*com\b)',
      caseSensitive: false,
      multiLine: true,
    );
    
    try {
      final matches = urlRegex.allMatches(output);
      print('Found ${matches.length} potential URL matches');
      
      for (final match in matches) {
        final rawUrl = match.group(0);
        print('Raw matched URL: $rawUrl');
        
        if (rawUrl != null) {
          // Clean the URL: remove spaces and ensure proper format
          final cleanUrl = rawUrl
              .replaceAll(RegExp(r'\s+'), '') // Remove all whitespace
              .replaceAll(RegExp(r':{2,}'), ':') // Fix multiple colons
              .toLowerCase(); // Normalize to lowercase
          
          print('Cleaned URL: $cleanUrl');
          
          // Validate the cleaned URL
          if (cleanUrl.contains('trycloudflare.com') && 
              cleanUrl.startsWith('http') &&
              cleanUrl != _cloudflaredUrl) {
            
            print('Valid new Cloudflare URL detected: $cleanUrl');
            
            setState(() {
              _cloudflaredUrl = cleanUrl;
            });
            
            _copyUrlToClipboard(cleanUrl);
          }
        }
      }
    } catch (e) {
      print('Error processing URL: $e');
      _addToTerminal('⚠️ Error processing Cloudflare URL: $e');
    }
  }
 // Updated process output handler
  void _addToTerminal(String message) {
    print('Terminal output: $message'); // Add logging
    setState(() {
      _terminalOutput.add(message.trim());
      // Keep only the last 1000 lines to prevent memory issues
      if (_terminalOutput.length > 1000) {
        _terminalOutput.removeAt(0);
      }
    });
    
    // Auto-scroll to the bottom after a brief delay
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
  // Improved clipboard handling
  Future<void> _copyUrlToClipboard(String url) async {
    try {
      print('Attempting to copy URL to clipboard: $url');
      
      await Clipboard.setData(ClipboardData(text: url));
      
      print('URL copied successfully');
      _addToTerminal('📋 New Cloudflare URL copied to clipboard: $url');
      
      // Show success message
      _showSnackBar(
        message: 'Cloudflare URL copied to clipboard',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      print('Error copying to clipboard: $e');
      _addToTerminal('⚠️ Error copying URL to clipboard: $e');
      
      // Show error message
      _showSnackBar(
        message: 'Failed to copy URL: $e',
        icon: Icons.error_outline,
        backgroundColor: Colors.red,
      );
    }
  }



  void _startServer(BuildContext context) {
    context.read<ProcessCubit>().startServer(_urlController.text);
  }

  void _stopServer(BuildContext context) {
    context.read<ProcessCubit>().stopServer();
  }

  void _startMining(BuildContext context) {
    context.read<ProcessCubit>().startMining();
  }

  void _stopMining(BuildContext context) {
    context.read<ProcessCubit>().stopMining();
  }
  @override
  void initState() {
    super.initState();
        // Initialize by checking cloudflared status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProcessCubit>().checkCloudflared();
    });

    _tabController = TabController(length: 2, vsync: this);
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProcessCubit, ProcessState>(
      builder: (context, state) {
        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1200) {
                return _buildWideLayout(state);
              } else if (constraints.maxWidth > 600) {
                return _buildMediumLayout(state);
              } else {
                return _buildNarrowLayout(state);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(ProcessState state) {
    return Row(
      children: [
        _buildSidebar(state),
        Expanded(
          flex: 3,
          child: _buildMainContent(state, isWide: true),
        ),
      ],
    );
  }

  Widget _buildMediumLayout(ProcessState state) {
    return Row(
      children: [
        if (_isExpanded) _buildSidebar(state),
        Expanded(
          child: _buildMainContent(state, isWide: false),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(ProcessState state) {
    return _buildMainContent(state, isWide: false);
  }

  Widget _buildSidebar(ProcessState state) {
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
                    _buildStatusCard(state),
                    SizedBox(height: 16),
                    _buildQuickActions(state),
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
  return BlocBuilder<WalletCubit, WalletState>(
    builder: (context, state) {
      if (state is WalletLoading) {
        return Center(
          child: CircularProgressIndicator(color: Colors.orange),
        );
      } else if (state is WalletLoaded) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
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
              const SizedBox(height: 12),
              Text(
                state.balance.toStringAsFixed(2),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      } else if (state is WalletError) {
        return Center(
          child: Text(
            '⚠️ Error loading balance',
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
          ),
        );
      }
      return SizedBox.shrink();
    },
  );
}

  Widget _buildStatusCard(ProcessState state) {
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
          _buildStatusRow('Cloudflared', state.isCloudflaredInstalled),
          SizedBox(height: 12),
          _buildStatusRow('Server', state.isServerRunning),
          SizedBox(height: 12),
          _buildStatusRow('Mining', state.isMining),
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

  Widget _buildMainContent(ProcessState state, {required bool isWide}) {
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
                    _buildMobileBalanceCard(state),
                    SizedBox(height: 24),
                  ],
                  _buildCloudflaredSection(state),
                  SizedBox(height: 24),
                  Expanded(child: _buildTerminal(state)),
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
          // IconButton(
          //   icon: Icon(Icons.help_outline, color: Colors.white),
          //   onPressed: () => _showHelpDialog(),
          // ),
        ],
      ),
    );
  }

  Widget _buildMobileBalanceCard(ProcessState state) {
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
                  '${state.currentBalance.toStringAsFixed(2)} SMP',
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
              Icons.wallet,
              color: Colors.orange,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildQuickActions(ProcessState state) {
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
          icon: state.isMining ? Icons.stop : Icons.play_arrow,
          label: state.isMining ? 'Stop Mining' : 'Start Mining',
          color: state.isMining ? Colors.red : Colors.green,
          onPressed: () => _handleMiningToggle(state),
        ),
        SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.refresh,
          label: 'Check Cloudflared',
          color: Colors.blue,
          onPressed: () => context.read<ProcessCubit>().checkCloudflared(),
        ),
      ],
    );
  }

  Widget _buildCloudflaredSection(ProcessState state) {
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
              hintText: 'Enter your server URL',
              prefixIcon: Icon(Icons.link, color: Colors.white54),
              suffixIcon: IconButton(
                icon: Icon(Icons.paste, color: Colors.white54),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
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
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildConfigButton(
                  icon: state.isServerRunning ? Icons.stop : Icons.play_circle_outline,
                  label: state.isServerRunning ? 'Stop Server' : 'Start Server',
                  color: state.isServerRunning ? Colors.red : Colors.green,
                  onPressed: () => _handleServerToggle(state),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildConfigButton(
                  icon: Icons.refresh,
                  label: 'Check Status',
                  color: Colors.blue,
                  onPressed: () => context.read<ProcessCubit>().checkCloudflared(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTerminal(ProcessState state) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildTerminalHeader(state),
          Expanded(
            child: _buildTerminalContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader(ProcessState state) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A4A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                onPressed: () => _copyTerminalOutput(state.terminalOutput),
                tooltip: 'Copy all',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.white70),
                onPressed: () => context.read<ProcessCubit>().clearTerminal(),
                tooltip: 'Clear terminal',
              ),
            ],
          ),
          if (state.cloudflaredUrl != null) ...[
            SizedBox(height: 12),
            _buildCloudflaredUrlSection(state.cloudflaredUrl!),
          ],
        ],
      ),
    );
  }

  Widget _buildCloudflaredUrlSection(String url) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  url,
                  style: GoogleFonts.firaCode(
                    color: Colors.blue,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: Colors.blue, size: 20),
                onPressed: () => _copyCloudflaredUrl(url),
                tooltip: 'Copy URL',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalContent(ProcessState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: state.terminalOutput.length,
      itemBuilder: (context, index) {
        final output = state.terminalOutput[index];
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
    );
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

 @override
  void dispose() {
    _urlController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}


