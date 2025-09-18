
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/relays_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// Modèles de données
class Relay {
  final String id;
  final String name;
  final double amperage;
  bool isOn;

  Relay({
    required this.id,
    required this.name,
    required this.amperage,
    this.isOn = false,
  });
}

class ConsumptionData {
  final DateTime time;
  final double value;

  ConsumptionData({required this.time, required this.value});
}

class SystemSettings {
  String kitNumber;
  List<String> controllerNumbers;
  bool systemStatus;

  SystemSettings({
    this.kitNumber = "ENM-001",
    this.controllerNumbers = const ["CTRL-01", "CTRL-02", "CTRL-03"],
    this.systemStatus = true,
  });
}

// Providers
final relaysProvider = StateNotifierProvider<RelaysNotifier, List<Relay>>((ref) {
  return RelaysNotifier();
});

final consumptionProvider = StateProvider<List<ConsumptionData>>((ref) {
  return List.generate(7, (index) => 
    ConsumptionData(
      time: DateTime.now().subtract(Duration(days: 6 - index)),
      value: 12.5 + (index * 2.3) + (index % 2 == 0 ? 1.5 : -1.2),
    )
  );
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SystemSettings>((ref) {
  return SettingsNotifier();
});

class RelaysNotifier extends StateNotifier<List<Relay>> {
  RelaysNotifier() : super([
    Relay(id: 'r1', name: 'Éclairage Salon', amperage: 2.5),
    Relay(id: 'r2', name: 'Réfrigérateur', amperage: 4.2),
    Relay(id: 'r3', name: 'Climatisation', amperage: 8.5),
  ]);

  void toggleRelay(String id) {
    state = state.map((relay) {
      if (relay.id == id) {
        relay.isOn = !relay.isOn;
        _sendSMSCommand('${relay.id}${relay.isOn ? 'On' : 'Off'}');
      }
      return relay;
    }).toList();
  }

  void _sendSMSCommand(String command) {
    print('Envoi SMS: $command');
  }
}

class SettingsNotifier extends StateNotifier<SystemSettings> {
  SettingsNotifier() : super(SystemSettings());

  void updateKitNumber(String newNumber) {
    state = SystemSettings(
      kitNumber: newNumber,
      controllerNumbers: state.controllerNumbers,
      systemStatus: state.systemStatus,
    );
  }

  void updateControllerNumbers(List<String> newNumbers) {
    state = SystemSettings(
      kitNumber: state.kitNumber,
      controllerNumbers: newNumbers,
      systemStatus: state.systemStatus,
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _pageTitles = [
    'Tableau de Bord',
    'Contrôle Relais',
    'Consommation',
    'Paramètres'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: _buildCleanAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFFFFFFF),
              Color(0xFFF1F5F9),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: const [
                HomeScreen(),
                RelaysScreen(),
                ConsumptionScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildCleanBottomNav(),
    );
  }

  PreferredSizeWidget _buildCleanAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.electrical_services, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ENMKit Control',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _pageTitles[_currentIndex],
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF64748B),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildCleanBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: CurvedNavigationBar(
        index: _currentIndex,
        height: 65,
        items: [
          Icon(Icons.dashboard_rounded, size: 26, color: _currentIndex == 0 ? Colors.white : const Color(0xFF64748B)),
          Icon(Icons.electrical_services, size: 26, color: _currentIndex == 1 ? Colors.white : const Color(0xFF64748B)),
          Icon(Icons.analytics_rounded, size: 26, color: _currentIndex == 2 ? Colors.white : const Color(0xFF64748B)),
          Icon(Icons.settings_rounded, size: 26, color: _currentIndex == 3 ? Colors.white : const Color(0xFF64748B)),
        ],
        color: Colors.white,
        buttonBackgroundColor: const Color(0xFF3B82F6),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutCubic,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        },
      ),
    );
  }
}

// ÉCRAN D'ACCUEIL ÉPURÉ
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildSystemStatus(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: Color(0xFF3B82F6),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenue sur ENMKit',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre système fonctionne parfaitement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat('3', 'Relais', Icons.power),
              _buildMiniStat('24.7', 'kWh', Icons.flash_on),
              _buildMiniStat('98%', 'Statut', Icons.check_circle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Actifs', '3 Relais', Icons.electrical_services, const Color(0xFF10B981))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Puissance', '15.2 kW', Icons.flash_on, const Color(0xFFF59E0B))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionButton('Contrôle', Icons.electrical_services, const Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton('Analyse', Icons.analytics, const Color(0xFF10B981))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton('Config', Icons.settings, const Color(0xFF8B5CF6))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Système Opérationnel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Dernière sync: il y a 2 minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// // ÉCRAN DES RELAIS ÉPURÉ
// class RelaysScreen extends ConsumerWidget {
//   const RelaysScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final relays = ref.watch(relaysProvider);
    
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),
//             ListView.separated(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: relays.length,
//               separatorBuilder: (context, index) => const SizedBox(height: 16),
//               itemBuilder: (context, index) => _buildCleanRelayCard(relays[index], ref),
//             ),
//             const SizedBox(height: 100),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCleanRelayCard(Relay relay, WidgetRef ref) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: relay.isOn 
//               ? const Color(0xFF10B981).withOpacity(0.3)
//               : const Color(0xFFE2E8F0),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: relay.isOn 
//                 ? const Color(0xFF10B981).withOpacity(0.1)
//                 : Colors.black.withOpacity(0.04),
//             blurRadius: relay.isOn ? 15 : 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               color: relay.isOn 
//                   ? const Color(0xFF10B981)
//                   : const Color(0xFFF1F5F9),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(
//               relay.isOn ? Icons.power : Icons.power_off,
//               color: relay.isOn ? Colors.white : const Color(0xFF64748B),
//               size: 26,
//             ),
//           ),
//           const SizedBox(width: 20),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   relay.name,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1E293B),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'ID: ${relay.id} • ${relay.amperage}A',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Color(0xFF64748B),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: relay.isOn 
//                         ? const Color(0xFF10B981).withOpacity(0.1)
//                         : const Color(0xFFF1F5F9),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     relay.isOn ? 'ACTIVÉ' : 'DÉSACTIVÉ',
//                     style: TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                       color: relay.isOn 
//                           ? const Color(0xFF10B981)
//                           : const Color(0xFF64748B),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Switch(
//             value: relay.isOn,
//             onChanged: (value) {
//               ref.read(relaysProvider.notifier).toggleRelay(relay.id);
//             },
//             activeColor: const Color(0xFF10B981),
//             activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
//             inactiveThumbColor: const Color(0xFF94A3B8),
//             inactiveTrackColor: const Color(0xFFE2E8F0),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ÉCRAN DE CONSOMMATION ÉPURÉ
class ConsumptionScreen extends ConsumerWidget {
  const ConsumptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumptionData = ref.watch(consumptionProvider);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildCurrentConsumption(),
            const SizedBox(height: 24),
            _buildConsumptionChart(consumptionData),
            const SizedBox(height: 24),
            _buildRefreshButton(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentConsumption() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.flash_on, color: Color(0xFF3B82F6), size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            '24.7 kWh',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consommation aujourd\'hui',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildConsumptionStat('2,847', 'Pulsations', Icons.timeline),
              _buildConsumptionStat('3.2A', 'Courant', Icons.electrical_services),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart(List<ConsumptionData> data) {
    double maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historique des 7 derniers jours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.asMap().entries.map((entry) {
                int index = entry.key;
                ConsumptionData consumption = entry.value;
                double heightPercentage = consumption.value / maxValue;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${consumption.value.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: (heightPercentage * 180).clamp(20.0, 180.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDayLabel(index),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(int index) {
    List<String> days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    DateTime now = DateTime.now();
    DateTime day = now.subtract(Duration(days: 6 - index));
    return days[day.weekday - 1];
  }

  Widget _buildRefreshButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
        label: const Text(
          'Actualiser la consommation',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// NOUVELLE ÉCRAN DE PARAMÈTRES
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _kitController = TextEditingController();
  final TextEditingController _controllerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSettingCard(
              'Numéro du Kit',
              'ENM-001',
              Icons.memory,
              () => _showEditDialog('Kit', _kitController),
            ),
            const SizedBox(height: 16),
            _buildSettingCard(
              'Contrôleurs',
              '${settings.controllerNumbers.length} configurés',
              Icons.device_hub,
              () => _showControllersDialog(),
            ),
            const SizedBox(height: 16),
            _buildSettingCard(
              'Générer QR Code',
              'Configuration système',
              Icons.qr_code,
              () => _showQRCodeDialog(),
            ),
            const SizedBox(height: 16),
            _buildSettingCard(
              'État Système',
              settings.systemStatus ? 'Opérationnel' : 'Arrêté',
              Icons.info_outline,
              () => _showSystemStatus(),
            ),
            const SizedBox(height: 16),
            _buildSettingCard(
              'Importer QR Code',
              'Mise à jour config',
              Icons.qr_code_scanner,
              () => _importQRCode(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

 Widget _buildSettingCard(
    String title, String subtitle, IconData icon, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8), // espacement entre cartes
      decoration: BoxDecoration(
        color: Colors.grey[100], // fond clair pour contraster avec le blanc du background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // texte foncé pour le contraste
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54, // texte secondaire plus léger
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.black38, // flèche discrète mais visible
            size: 16,
          ),
        ],
      ),
    ),
  );
}


void _showEditDialog( String field, TextEditingController controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text(
        'Modifier $field',
        style: const TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Entrer nouveau $field',
          hintStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF3B82F6)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (field == 'Kit') {
              final kitVM = ref.read(kitProvider.notifier);
              final newKitNumber = controller.text.trim();

              if (newKitNumber.isNotEmpty) {
                try {
                  // Vérifie s’il existe déjà un kit
                  final existingKit = await kitVM.getKitNumber();
                  if (existingKit != null) {
                    // Mettre à jour le kit existant
                    await kitVM.updateKit(
                      KitModel(kitNumber: newKitNumber),
                    );
                  } else {
                    // Ajouter un nouveau kit
                    await kitVM.addKit(
                      KitModel(kitNumber: newKitNumber),
                    );
                  }
                  // Rafraîchir la liste
                  await kitVM.fetchKits();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur lors de la mise à jour : $e")),
                  );
                }
              }
            }
            Navigator.pop(context);
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    ),
  );
}


  void _showControllersDialog() {
    final settings = ref.read(settingsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Contrôleurs', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: settings.controllerNumbers.map((controller) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.device_hub, color: Color(0xFF3B82F6), size: 16),
                    const SizedBox(width: 8),
                    Text(controller, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            )
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showAddControllerDialog();
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showAddControllerDialog() {
    final TextEditingController newController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Ajouter Contrôleur', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: newController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ex: CTRL-04',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3B82F6)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () {
              if (newController.text.isNotEmpty) {
                final currentSettings = ref.read(settingsProvider);
                final newList = [...currentSettings.controllerNumbers, newController.text];
                ref.read(settingsProvider.notifier).updateControllerNumbers(newList);
              }
              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog() {
    final settings = ref.read(settingsProvider);
    final qrData = {
      'kit': settings.kitNumber,
      'controllers': settings.controllerNumbers,
      'status': settings.systemStatus,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('QR Code Configuration', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 80, color: Colors.black),
                    SizedBox(height: 8),
                    Text(
                      'QR CODE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Configuration système générée',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              // Logique de partage du QR Code
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR Code sauvegardé!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Partager'),
          ),
        ],
      ),
    );
  }

  void _showSystemStatus() {
    final settings = ref.read(settingsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('État du Système', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: settings.systemStatus 
                    ? const Color(0xFF10B981).withOpacity(0.2)
                    : const Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: settings.systemStatus 
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    settings.systemStatus ? Icons.check_circle : Icons.error,
                    color: settings.systemStatus 
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    settings.systemStatus ? 'OPÉRATIONNEL' : 'ARRÊTÉ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: settings.systemStatus 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.systemStatus 
                        ? 'Tous les systèmes fonctionnent normalement'
                        : 'Le système nécessite une attention',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusInfo('Kit:', settings.kitNumber),
            _buildStatusInfo('Contrôleurs:', '${settings.controllerNumbers.length} actifs'),
            _buildStatusInfo('Dernière sync:', 'Il y a 2 minutes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.white70)),
          ),
          if (!settings.systemStatus)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                // Logique de redémarrage du système
                Navigator.pop(context);
              },
              child: const Text('Redémarrer'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _importQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Importer QR Code', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6), style: BorderStyle.solid, width: 2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, color: Color(0xFF3B82F6), size: 60),
                  SizedBox(height: 8),
                  Text(
                    'Scanner QR',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scannez un QR Code de configuration\npour mettre à jour le système',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () {
              // Logique de scan QR Code
              Navigator.pop(context);
              _showImportSuccess();
            },
            child: const Text('Ouvrir Scanner'),
          ),
        ],
      ),
    );
  }

  void _showImportSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Import Réussi!', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 60),
            const SizedBox(height: 16),
            const Text(
              'Configuration mise à jour avec succès',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kit:', style: TextStyle(color: Colors.white70)),
                      Text('ENM-002', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Contrôleurs:', style: TextStyle(color: Colors.white70)),
                      Text('4 nouveaux', style: TextStyle(color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(context);
              // Optionnel: redémarrer l'application ou recharger les données
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _kitController.dispose();
    _controllerController.dispose();
    super.dispose();
  }
}