import 'package:enmkit/providers.dart';
import 'package:enmkit/viewmodels/relayViewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/models/relay_model.dart';


class RelaysScreen extends ConsumerWidget {
  const RelaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relayViewModel = ref.watch(relaysProvider);
    final relays = relayViewModel.relays;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (relayViewModel.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: relays.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _buildCleanRelayCard(context, relays[index], relayViewModel),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanRelayCard(
      BuildContext context, RelayModel relay, RelayViewModel viewModel) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relay.name??"Relais${relay.id}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "État actuel: ${relay.isActive ? "ON" : "OFF"}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: relay.isActive,
              onChanged: (value) async {
                try {
                  await viewModel.toggleRelay(relay);
                } catch (e) {
                  // Afficher une snackbar en cas d'échec du SMS
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Échec du changement d'état : $e")),
                  );
                }
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
