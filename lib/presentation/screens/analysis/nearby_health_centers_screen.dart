import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/health_center_model.dart';
import '../../../data/services/health_center_locator_service.dart';

/// 🏥 CENTRES DE SANTÉ À PROXIMITÉ
///
/// Affichée après un résultat de test à risque élevé, pour orienter
/// concrètement l'utilisateur vers une prise en charge médicale.
class NearbyHealthCentersScreen extends StatefulWidget {
  const NearbyHealthCentersScreen({Key? key}) : super(key: key);

  @override
  State<NearbyHealthCentersScreen> createState() =>
      _NearbyHealthCentersScreenState();
}

class _NearbyHealthCentersScreenState
    extends State<NearbyHealthCentersScreen> {
  List<HealthCenterModel>? _centers;
  bool _loading = true;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final position = await HealthCenterLocatorService.getCurrentPosition();
    final centers = await HealthCenterLocatorService.findNearby(
      lat: position?.latitude,
      lon: position?.longitude,
    );
    if (!mounted) return;
    setState(() {
      _centers = centers;
      _locationDenied = position == null;
      _loading = false;
    });
  }

  Future<void> _openDirections(HealthCenterModel center) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${center.latitude},${center.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le plan')),
      );
    }
  }

  Future<void> _callSamu() async {
    final uri = Uri(scheme: 'tel', path: '185');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Centres de santé à proximité'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.emergency, color: Colors.red.shade700),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'En cas d\'urgence vitale, appelez immédiatement le SAMU',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _callSamu,
                    child: const Text('185'),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.08, end: 0),
            if (_locationDenied && !_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '📍 Position non disponible — résultats basés sur Abidjan par défaut. '
                  'Autorisez la localisation pour des résultats plus précis.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final centers = _centers ?? [];
    if (centers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.grey)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 500.ms),
              const SizedBox(height: 12),
              const Text(
                'Aucun centre de santé référencé à proximité dans notre base.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Consultez votre centre de santé habituel ou appelez le SAMU (185).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: centers.length,
      itemBuilder: (context, index) {
        final center = centers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.local_hospital, color: AppColors.primary),
            title: Text(center.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${center.typeLabel} · ${center.distanceKm.toStringAsFixed(1)} km',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.directions, color: AppColors.primary),
              tooltip: 'Itinéraire',
              onPressed: () => _openDirections(center),
            ),
            onTap: () => _openDirections(center),
          ),
        ).animate().fadeIn(delay: (50 * index).ms, duration: 300.ms).slideX(begin: 0.08, end: 0);
      },
    );
  }
}
