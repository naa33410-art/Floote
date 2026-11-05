import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const ElectroScannerApp());

class ElectroScannerApp extends StatelessWidget {
  const ElectroScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electro Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35E0B5),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF08111B),
        cardColor: const Color(0xFF111F2D),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      OverviewPage(onNavigate: (v) => setState(() => _tab = v)),
      AcousticPage(),
      MagneticPage(),
      BluetoothPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELECTRO SCANNER',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.3)),
        centerTitle: true,
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (v) => setState(() => _tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.radar), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: 'Som'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Magnetismo'),
          NavigationDestination(icon: Icon(Icons.bluetooth_searching), label: 'BLE'),
        ],
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const OverviewPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.radar, size: 76, color: Color(0xFF35E0B5)),
        const SizedBox(height: 8),
        const Text('Inspeção de ambiente',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Use os módulos separadamente para procurar sinais que mereçam investigação. '
            'Um sinal detectado não confirma a presença de um rastreador.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
        _moduleCard(context, Icons.graphic_eq, 'Detector acústico',
            'Mede o nível do som captado pelo microfone.', 1, onNavigate),
        _moduleCard(context, Icons.explore, 'Detector magnético',
            'Mostra o campo magnético medido pelo sensor do aparelho.', 2, onNavigate),
        _moduleCard(context, Icons.bluetooth_searching, 'Radar Bluetooth BLE',
            'Procura anúncios Bluetooth Low Energy próximos.', 3, onNavigate),
        const SizedBox(height: 12),
        const Text(
          'Limites: o celular não detecta diretamente GPS, rede celular ou toda a radiofrequência. '
          'Alguns rastreadores não anunciam Bluetooth continuamente ou usam identificadores variáveis.',
          style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _moduleCard(BuildContext context, IconData icon, String title,
      String subtitle, int tab, ValueChanged<int> onNavigate) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF35E0B5), size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onNavigate(tab),
      ),
    );
  }
}

class AcousticPage extends StatefulWidget {
  const AcousticPage({super.key});
  @override
  State<AcousticPage> createState() => _AcousticPageState();
}

class _AcousticPageState extends State<AcousticPage> {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<List<int>>? _sub;
  double _level = 0;
  bool _running = false;
  String _status = 'Parado';

  Future<void> _toggle() async {
    if (_running) {
      await _sub?.cancel();
      _sub = null;
      await _recorder.stop();
      if (mounted) setState(() { _running = false; _status = 'Parado'; });
      return;
    }
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      setState(() => _status = 'Permissão de microfone negada');
      return;
    }
    try {
      final stream = await _recorder.startStream(
        const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
      );
      _sub = stream.listen((bytes) {
        if (bytes.length < 2) return;
        double sum = 0;
        int count = 0;
        for (int i = 0; i + 1 < bytes.length; i += 2) {
          int sample = bytes[i] | (bytes[i + 1] << 8);
          if (sample > 32767) sample -= 65536;
          final normalized = sample / 32768.0;
          sum += normalized * normalized;
          count++;
        }
        final rms = count == 0 ? 0.0 : math.sqrt(sum / count);
        if (mounted) setState(() => _level = rms.clamp(0.0, 1.0));
      });
      setState(() { _running = true; _status = 'Capturando áudio'; });
    } catch (e) {
      setState(() => _status = 'Não foi possível iniciar: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.graphic_eq, size: 62, color: Color(0xFF35E0B5)),
          const SizedBox(height: 12),
          const Text('Detector acústico', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 28),
          Text('${(_level * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
          const Text('Nível relativo de áudio (RMS)', textAlign: TextAlign.center),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: _level, minHeight: 14),
          const Spacer(),
          FilledButton.icon(
            onPressed: _toggle,
            icon: Icon(_running ? Icons.stop : Icons.mic),
            label: Text(_running ? 'Parar captura' : 'Iniciar captura'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Esta primeira versão mostra intensidade sonora, não identifica automaticamente um rastreador nem separa frequências. '
            'Evite gravar conversas de terceiros.',
            style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class MagneticPage extends StatefulWidget {
  const MagneticPage({super.key});
  @override
  State<MagneticPage> createState() => _MagneticPageState();
}

class _MagneticPageState extends State<MagneticPage> {
  StreamSubscription<MagnetometerEvent>? _sub;
  double _x = 0, _y = 0, _z = 0, _total = 0;
  String _status = 'Aguardando sensor';
  bool _running = false;

  void _toggle() {
    if (_running) {
      _sub?.cancel();
      setState(() { _running = false; _status = 'Parado'; });
      return;
    }
    _sub = magnetometerEventStream().listen((e) {
      final total = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (mounted) setState(() {
        _x = e.x; _y = e.y; _z = e.z; _total = total;
        _status = 'Sensor ativo';
      });
    }, onError: (e) {
      if (mounted) setState(() => _status = 'Sensor indisponível: $e');
    });
    setState(() { _running = true; _status = 'Sensor ativo'; });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.explore, size: 62, color: Color(0xFF35E0B5)),
          const SizedBox(height: 12),
          const Text('Detector magnético',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          Text(_status, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 28),
          Text('${_total.toStringAsFixed(1)} µT',
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
          const Text('Magnitude do campo magnético'),
          const SizedBox(height: 20),
          _axis('X', _x), _axis('Y', _y), _axis('Z', _z),
          const Spacer(),
          FilledButton.icon(
            onPressed: _toggle,
            icon: Icon(_running ? Icons.stop : Icons.play_arrow),
            label: Text(_running ? 'Parar leitura' : 'Iniciar leitura'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Metais, ímãs, alto-falantes e componentes do próprio veículo podem alterar a leitura. '
            'Uma alteração não comprova a existência de rastreador.',
            style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _axis(String label, double value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 24, child: Text(label)),
      Expanded(child: LinearProgressIndicator(value: (value.abs() / 100).clamp(0.0, 1.0))),
      const SizedBox(width: 10),
      SizedBox(width: 75, child: Text('${value.toStringAsFixed(1)} µT', textAlign: TextAlign.end)),
    ]),
  );
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});
  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final Map<String, ScanResult> _results = {};
  StreamSubscription<List<ScanResult>>? _scanSub;
  bool _scanning = false;
  String _status = 'Pronto para procurar';

  Future<bool> _permissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  Future<void> _start() async {
    if (!await _permissions()) {
      setState(() => _status = 'Permissões necessárias não concedidas');
      return;
    }
    try {
      if (await FlutterBluePlus.isSupported == false) {
        setState(() => _status = 'Bluetooth BLE não suportado neste aparelho');
        return;
      }
      final adapter = await FlutterBluePlus.adapterState.first;
      if (adapter != BluetoothAdapterState.on) {
        setState(() => _status = 'Ative o Bluetooth do celular');
        return;
      }
      _results.clear();
      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.onScanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          for (final r in results) {
            final id = r.device.remoteId.str;
            final old = _results[id];
            if (old == null || r.rssi > old.rssi || DateTime.now().millisecondsSinceEpoch % 3 == 0) {
              _results[id] = r;
            }
          }
        });
      }, onError: (e) {
        if (mounted) setState(() => _status = 'Erro na busca: $e');
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      setState(() { _scanning = true; _status = 'Busca em andamento (15 segundos)'; });
      await Future.delayed(const Duration(seconds: 15));
      if (mounted) setState(() { _scanning = false; _status = 'Busca concluída'; });
    } catch (e) {
      if (mounted) setState(() { _scanning = false; _status = 'Falha ao procurar: $e'; });
    }
  }

  Future<void> _stop() async {
    await FlutterBluePlus.stopScan();
    if (mounted) setState(() { _scanning = false; _status = 'Busca interrompida'; });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _results.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.bluetooth_searching, size: 62, color: Color(0xFF35E0B5)),
          const SizedBox(height: 8),
          const Text('Radar Bluetooth BLE',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          Text(_status, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _scanning ? _stop : _start,
            icon: Icon(_scanning ? Icons.stop : Icons.radar),
            label: Text(_scanning ? 'Parar busca' : 'Procurar dispositivos'),
          ),
          const SizedBox(height: 8),
          Text('${entries.length} dispositivo(s) encontrado(s)',
              style: const TextStyle(color: Color(0xFF35E0B5))),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('Nenhum anúncio BLE encontrado nesta busca.'))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final r = entries[index];
                      final name = r.device.platformName.isNotEmpty
                          ? r.device.platformName
                          : 'Dispositivo sem nome';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth, color: Color(0xFF35E0B5)),
                          title: Text(name),
                          subtitle: Text('${r.device.remoteId.str}\nRSSI: ${r.rssi} dBm'),
                          isThreeLine: true,
                          trailing: Text(_signalLabel(r.rssi)),
                        ),
                      );
                    },
                  ),
          ),
          const Text(
            'A lista inclui celulares, fones, relógios e outros aparelhos. RSSI não mede distância com precisão e não confirma rastreadores. '
            'Identificadores podem mudar.',
            style: TextStyle(fontSize: 11, color: Colors.orangeAccent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _signalLabel(int rssi) {
    if (rssi >= -55) return 'Forte';
    if (rssi >= -75) return 'Médio';
    return 'Fraco';
  }
}
