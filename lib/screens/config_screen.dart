import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/foundation.dart';
import 'package:mgr_settings_gui/mygadgetrepairs_cli.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager_plus/window_manager_plus.dart';

// Only for testing and displaying the actual config window design
Future<void> main(List<String> args) async {
  if (kDebugMode == true) {
    log('Starting application debug/sample/standalone application...');
    WidgetsFlutterBinding.ensureInitialized();
    runApp(ConfigScreen());
  }
  throw Exception('Not a standalone application');
}

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
  final ConfigService _configService = ConfigService();
  late TextEditingController _telavoxJwtTokenController;
  late TextEditingController _telavoxBaseUrlController;
  late int _telavoxPollInterval;
  late int _telavoxExemptionTime;

  // --- MGR API State Variables ---
  late TextEditingController _mgrApiKeyController;
  MgrClient? _mgrClient;
  Resources? _selectedMgrResource = Resources.inboundCall; // Default selection
  final TextEditingController _mgrResourceIdController =
      TextEditingController();
  String _mgrApiResponseText = '';
  bool _isLoadingMgrApi = false;

  // --- End MGR API State ---
  @override
  initState() {
    super.initState();
    _telavoxJwtTokenController = TextEditingController();
    _telavoxBaseUrlController = TextEditingController();
    _telavoxPollInterval = 5;
    _telavoxExemptionTime = 2;
    _mgrApiKeyController = TextEditingController();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    // Telavox
    _telavoxJwtTokenController.dispose();
    _telavoxBaseUrlController.dispose();
    _telavoxPollInterval = 5; // Default
    _telavoxExemptionTime = 2; // Default
    // MGR
    _mgrApiKeyController.dispose();
    _mgrResourceIdController.dispose();
    super.dispose();
  }

  void _loadCurrentConfig() async {
    final config = await _configService.loadConfig();
    if (mounted) {
      setState(() {
        // Telavox
        _telavoxJwtTokenController.text = config.telavoxJwtToken ?? '';
        _telavoxBaseUrlController.text = config.telavoxBaseUrl;
        _telavoxPollInterval = config.telavoxPollInterval;
        _telavoxExemptionTime = config.telavoxExemptionTime;

        // MGR
        _mgrApiKeyController.text = config.mgrApiKey ?? '';
        //  _updateMgrClient(); // Initialize MGR client if API key exists
      });
    }
  }

  void _saveConfig() async {
    try {
      await _configService.updateConfig(
        // Telavox
        telavoxJwtToken: _telavoxJwtTokenController.text,
        telavoxBaseUrl: _telavoxBaseUrlController.text,
        telavoxPollInterval: _telavoxPollInterval,
        telavoxExemptionTime: _telavoxExemptionTime,

        // MGR
        mgrApiKey: _mgrApiKeyController.text,
      );
      // _updateMgrClient(); // Update MGR client in case API key changed

      if (mounted) {
        displayInfoBar(
          context,
          builder:
              (context, close) => InfoBar(
                title: const Text('Configuration Saved'),
                content: Text(
                  'Successfully saved file to: ${_configService.configFile.path}',
                ),
                severity: InfoBarSeverity.success,
                action: IconButton(
                  icon: const Icon(FluentIcons.clear),
                  onPressed: close,
                ),
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder:
              (context, close) => InfoBar(
                title: const Text('Save Error'),
                content: Text('Failed to save configuration: ${e.toString()}'),
                severity: InfoBarSeverity.error,
                action: IconButton(
                  icon: const Icon(FluentIcons.clear),
                  onPressed: close,
                ),
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Application Configuration'),
        commandBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CommandBar(
              primaryItems: [
                CommandBarButton(
                  icon: const Icon(FluentIcons.save),
                  label: const Text('Save All Configuration'),
                  onPressed: _saveConfig,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(FluentIcons.cancel),
              onPressed: () async {
                await WindowManagerPlus.current.hide();
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(EdgeInsets.all(8)),
              ),
            ),
          ],
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Telavox Monitor Configuration',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 10),
          InfoLabel(
            label: 'Telavox JWT Token',
            child: TextBox(
              controller: _telavoxJwtTokenController,
              placeholder: 'Enter your Telavox JWT Token',
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 20),
          InfoLabel(
            label: 'Telavox Base URL',
            child: TextBox(
              controller: _telavoxBaseUrlController,
              placeholder: 'https://api.telavox.se',
            ),
          ),
          const SizedBox(height: 20),
          InfoLabel(
            label: 'Telavox Poll Interval (seconds)',
            child: NumberBox<int>(
              value: _telavoxPollInterval,
              onChanged: (value) {
                if (mounted) setState(() => _telavoxPollInterval = value ?? 5);
              },
              min: 1,
              max: 60,
            ),
          ),
          const SizedBox(height: 20),
          InfoLabel(
            label: 'Telavox Exemption Time (minutes)',
            child: NumberBox<int>(
              value: _telavoxExemptionTime,
              onChanged: (value) {
                if (mounted) setState(() => _telavoxExemptionTime = value ?? 2);
              },
              min: 1,
              max: 60,
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            'MGR API Test Utility',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 20),
          InfoLabel(
            label: 'MGR API Key',
            child: TextBox(
              controller: _mgrApiKeyController,
              placeholder: 'Enter your MGR API Key',
              maxLines: 1,
              onChanged:
                  (_) => _updateMgrClient(), // Update client on key change
            ),
          ),
          const SizedBox(height: 20),
          InfoLabel(
            label: 'Select MGR API Resource:',
            child: ComboBox<Resources>(
              value: _selectedMgrResource,
              items:
                  Resources.values.map((Resources resource) {
                    return ComboBoxItem<Resources>(
                      value: resource,
                      child: Text(resource.name),
                    );
                  }).toList(),
              onChanged: (Resources? value) {
                if (value != null) {
                  setState(() {
                    _selectedMgrResource = value;
                    _mgrResourceIdController.clear();
                    _mgrApiResponseText = '';
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed:
                (_mgrClient == null ||
                        _selectedMgrResource == null ||
                        _isLoadingMgrApi)
                    ? null
                    : _makeMgrApiCall,
            child:
                _isLoadingMgrApi
                    ? const ProgressRing()
                    : Text(
                      'Call MGR API: ${_selectedMgrResource?.name ?? "Resource"}',
                    ),
          ),
          const SizedBox(height: 20),
          if (_mgrApiResponseText.isNotEmpty) ...[
            InfoLabel(
              label: 'MGR API Response:',
              child: Card(
                padding: const EdgeInsets.all(10),
                child: SelectableText(
                  _mgrApiResponseText,
                  style: FluentTheme.of(context).typography.body,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateMgrClient() {
    if (_mgrApiKeyController.text.isNotEmpty) {
      setState(() {
        _mgrClient = MgrClient(apiKey: _mgrApiKeyController.text);
      });
    } else {
      setState(() {
        _mgrClient = null;
      });
    }
  }

  Future<void> _makeMgrApiCall() async {
    if (_mgrClient == null) {
      setState(() {
        _mgrApiResponseText =
            'Error: MGR API Key is not set or client not initialized.';
      });
      return;
    }
    if (_selectedMgrResource == null) {
      setState(() {
        _mgrApiResponseText = 'Error: No MGR API resource selected.';
      });
      return;
    }

    setState(() {
      _isLoadingMgrApi = true;
      _mgrApiResponseText = 'Loading...';
    });

    try {
      dynamic response;

      log("Making MGR API call to $_selectedMgrResource ");
      response = await _mgrClient!.request(resource: _selectedMgrResource!);

      setState(() {
        if (response == null) {
          _mgrApiResponseText = 'Operation successful (No content returned).';
        } else {
          _mgrApiResponseText = 'Success:\n${response.toString()}';
          if (response is UserResource) {
            _mgrApiResponseText +=
                '\nRaw Data:\n${JsonEncoder.withIndent('  ').convert(response.rawData)}';
          } else if (response is List<UserResource>) {
            _mgrApiResponseText +=
                '\nRaw Data:\n${JsonEncoder.withIndent('  ').convert(response.map((e) => e.rawData).toList())}';
          }
          // Add handling for other response types like ResourceIdResponse if you implement it
        }
      });
    } catch (e) {
      setState(() {
        _mgrApiResponseText = 'Error:\n${e.toString()}';
      });
      log("MGR API Call Error: $e");
    } finally {
      setState(() {
        _isLoadingMgrApi = false;
      });
    }
  }
}

class Config {
  // Telavox fields
  final String? telavoxJwtToken;
  final String telavoxBaseUrl;
  final int telavoxPollInterval;
  final int telavoxExemptionTime;

  // MGR field
  final String? mgrApiKey;

  // Shared (if any, e.g., recentCalls was there before)
  final Map<String, dynamic>? recentCalls;

  Config({
    // Telavox
    this.telavoxJwtToken,
    this.telavoxBaseUrl = 'https://api.telavox.se', // Default Telavox URL
    this.telavoxPollInterval = 5,
    this.telavoxExemptionTime = 2,

    // MGR
    this.mgrApiKey,

    // Shared
    this.recentCalls,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      // Telavox
      telavoxJwtToken: json['telavox_credentials']?['jwt_token'],
      telavoxBaseUrl:
          json['telavox_settings']?['base_url'] ?? 'https://api.telavox.se',
      telavoxPollInterval: json['telavox_settings']?['poll_interval'] ?? 5,
      telavoxExemptionTime: json['telavox_settings']?['exemption_time'] ?? 2,

      // MGR
      mgrApiKey: json['mgr_credentials']?['api_key'],

      // Shared
      recentCalls: json['recent_calls'],
    );
  }

  Map<String, dynamic> toJson() => {
    'telavox_credentials': {'jwt_token': telavoxJwtToken},
    'telavox_settings': {
      'base_url': telavoxBaseUrl,
      'poll_interval': telavoxPollInterval,
      'exemption_time': telavoxExemptionTime,
    },
    'mgr_credentials': {'api_key': mgrApiKey},
    'recent_calls': recentCalls ?? {},
  };

  Config copyWith({
    // Use Opt<T> pattern for nullable fields if you need to distinguish
    // between 'not set' and 'set to null'. For simplicity here, just nullable.
    String? telavoxJwtToken,
    String? telavoxBaseUrl,
    int? telavoxPollInterval,
    int? telavoxExemptionTime,
    String? mgrApiKey,
    Map<String, dynamic>? recentCalls,
  }) {
    return Config(
      telavoxJwtToken: telavoxJwtToken ?? this.telavoxJwtToken,
      telavoxBaseUrl: telavoxBaseUrl ?? this.telavoxBaseUrl,
      telavoxPollInterval: telavoxPollInterval ?? this.telavoxPollInterval,
      telavoxExemptionTime: telavoxExemptionTime ?? this.telavoxExemptionTime,
      mgrApiKey: mgrApiKey ?? this.mgrApiKey,
      recentCalls: recentCalls ?? this.recentCalls,
    );
  }
}

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() => _instance;

  ConfigService._internal();

  File get configFile {
    final appDir = Directory(
      path.join(
        Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            '.',
        '.telavox-monitor-config', // Unified config folder name
      ),
    );
    if (!appDir.existsSync()) appDir.createSync(recursive: true);
    return File(
      path.join(appDir.path, 'app_config.json'),
    ); // Unified config file name
  }

  Future<Config> loadConfig() async {
    if (!configFile.existsSync()) return Config(); // Return default for all
    try {
      final contents = await configFile.readAsString();
      if (contents.isEmpty) return Config();
      final Map<String, dynamic> json = jsonDecode(contents);
      return Config.fromJson(json);
    } catch (e) {
      log("Error loading config: $e");
      return Config(); // Return default on error
    }
  }

  Future<void> updateConfig({
    // Telavox
    String? telavoxJwtToken,
    String? telavoxBaseUrl,
    int? telavoxPollInterval,
    int? telavoxExemptionTime,
    // MGR
    String? mgrApiKey,
  }) async {
    final currentConfig = await loadConfig();
    final newConfig = currentConfig.copyWith(
      // Telavox
      telavoxJwtToken: telavoxJwtToken,
      telavoxBaseUrl: telavoxBaseUrl,
      telavoxPollInterval: telavoxPollInterval,
      telavoxExemptionTime: telavoxExemptionTime,
      // MGR
      mgrApiKey: mgrApiKey,
      // Shared (ensure it's preserved if not updated)
      recentCalls: currentConfig.recentCalls,
    );
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(newConfig.toJson()),
    );
  }
}
