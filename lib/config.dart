import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:path/path.dart' as path;
import 'package:window_manager_plus/window_manager_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FluentApp(home: ConfigScreen()));
}

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConfigScreenState createState() => ConfigScreenState();
}

class Config {
  final String? jwtToken;
  final String baseUrl;
  final int pollInterval;
  final int exemptionTime;
  final Map<String, dynamic>? recentCalls;

  Config({
    this.jwtToken,
    this.baseUrl = 'https://api.telavox.se',
    this.pollInterval = 5,
    this.exemptionTime = 2,
    this.recentCalls,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      jwtToken: json['credentials']?['jwt_token'],
      baseUrl: json['settings']?['base_url'] ?? 'https://api.telavox.se',
      pollInterval: json['settings']?['poll_interval'] ?? 5,
      exemptionTime: json['settings']?['exemption_time'] ?? 2,
      recentCalls: json['recent_calls'],
    );
  }

  Map<String, dynamic> toJson() => {
    'credentials': {'jwt_token': jwtToken},
    'settings': {
      'base_url': baseUrl,
      'poll_interval': pollInterval,
      'exemption_time': exemptionTime,
    },
    'recent_calls': recentCalls ?? {},
  };

  Config copyWith({
    String? jwtToken,
    String? baseUrl,
    int? pollInterval,
    int? exemptionTime,
  }) {
    return Config(
      jwtToken: jwtToken ?? this.jwtToken,
      baseUrl: baseUrl ?? this.baseUrl,
      pollInterval: pollInterval ?? this.pollInterval,
      exemptionTime: exemptionTime ?? this.exemptionTime,
      recentCalls: recentCalls,
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
        '.telavox-monitor',
      ),
    );

    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }

    return File(path.join(appDir.path, 'config.json'));
  }

  Future<Config> loadConfig() async {
    if (!configFile.existsSync()) {
      return Config(); // Return default config
    }

    try {
      final contents = await configFile.readAsString();
      final Map<String, dynamic> json = jsonDecode(contents);
      return Config.fromJson(json);
    } catch (e) {
      // If there's an error reading the config, return default
      return Config();
    }
  }

  Future<void> updateConfig({
    String? jwtToken,
    String? baseUrl,
    int? pollInterval,
    int? exemptionTime,
  }) async {
    final currentConfig = await loadConfig();

    final newConfig = currentConfig.copyWith(
      jwtToken: jwtToken,
      baseUrl: baseUrl,
      pollInterval: pollInterval,
      exemptionTime: exemptionTime,
    );

    await configFile.writeAsString(
      JsonEncoder.withIndent('  ').convert(newConfig.toJson()),
    );
  }
}

class ConfigScreenState extends State<ConfigScreen> {
  final ConfigService _configService = ConfigService();
  late TextEditingController _jwtTokenController;
  late TextEditingController _baseUrlController;
  late int _pollInterval;
  late int _exemptionTime;
  late WindowManagerPlus window;
  @override
  Future<void> initState() async {
    super.initState();
    _jwtTokenController = TextEditingController();
    _baseUrlController = TextEditingController();
    _pollInterval = 5;
    _exemptionTime = 2;
    _loadCurrentConfig();
    await WindowManagerPlus.ensureInitialized(
      (await WindowManagerPlus.getAllWindowManagerIds()).lastOrNull ?? 0,
    ).then((value) async {
      window = await createWindow;
      log('Window creation was successful');
    });
  }

  @override
  void dispose() {
    _jwtTokenController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<WindowManagerPlus> get createWindow async =>
      await WindowManagerPlus.createWindow(['config']) ??
      WindowManagerPlus.current;
  Future<void> show() async {
    // Get the window from the window manager
    await window.show();
  }

  Future<void> hide() async {
    // Get the window from the window manager
    await window.hide();
  }

  void _loadCurrentConfig() async {
    final config = await _configService.loadConfig();
    setState(() {
      _jwtTokenController.text = config.jwtToken ?? '';
      _baseUrlController.text = config.baseUrl;
      _pollInterval = config.pollInterval;
      _exemptionTime = config.exemptionTime;
    });
  }

  void _saveConfig() async {
    try {
      await _configService.updateConfig(
        jwtToken: _jwtTokenController.text,
        baseUrl: _baseUrlController.text,
        pollInterval: _pollInterval,
        exemptionTime: _exemptionTime,
      );

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
    } catch (e) {
      displayInfoBar(
        context,
        builder:
            (context, close) => InfoBar(
              title: const Text('Validation Error'),
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Application Configuration'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('Save Configuration'),
              onPressed: _saveConfig,
            ),
          ],
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InfoLabel(
            label: 'JWT Token',
            child: TextBox(
              controller: _jwtTokenController,
              placeholder: 'Enter your Telavox JWT Token',
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 20),
          InfoLabel(
            label: 'Base URL',
            child: TextBox(
              controller: _baseUrlController,
              placeholder: 'https://api.telavox.se',
            ),
          ),
          const SizedBox(height: 20),
          InfoLabel(
            label: 'Poll Interval (seconds)',
            child: NumberBox<int>(
              value: _pollInterval,
              onChanged: (value) => setState(() => _pollInterval = value ?? 5),
              min: 1,
              max: 60,
            ),
          ),
          const SizedBox(height: 20),
          InfoLabel(
            label: 'Exemption Time (minutes)',
            child: NumberBox<int>(
              value: _exemptionTime,
              onChanged: (value) => setState(() => _exemptionTime = value ?? 2),
              min: 1,
              max: 60,
            ),
          ),
        ],
      ),
    );
  }
}
