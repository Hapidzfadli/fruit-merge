import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/sfx_service.dart';
import '../game/fruit_sprites.dart';
import 'theme.dart';
import 'settings_page.dart';
import 'shop_page.dart';
import 'game_page.dart';
import '../state/app_state.dart';
import 'ranking_page.dart';
import 'collection_page.dart';

/// Port of buildMenuScreen() (app.js:169-202).
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kScreenGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative floating fruit dots — app.js:172-178
              const Positioned(
                top: 40,
                left: 22,
                child: Opacity(
                  opacity: 0.85,
                  child: FruitImage(index: 0, size: 34),
                ),
              ),
              const Positioned(
                top: 90,
                right: 26,
                child: Opacity(
                  opacity: 0.85,
                  child: FruitImage(index: 2, size: 28),
                ),
              ),
              const Positioned(
                top: 140,
                left: 44,
                child: Opacity(
                  opacity: 0.7,
                  child: FruitImage(index: 3, size: 24),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        // Title — app.js:180-184
                        Column(
                          children: [
                            Text(
                              'FRUIT MERGE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 34,
                                letterSpacing: 0.6,
                                color: AppColors.coral,
                                shadows: const [
                                  Shadow(
                                    color: Colors.white,
                                    offset: Offset(2, 2),
                                  ),
                                  Shadow(
                                    color: Color(0x40FF6B4A),
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'ADVENTURE',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                letterSpacing: 3,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Mascot — the bear cub app.js drew out of stacked divs
                        // (buildMascot, app.js:151-166), now real artwork. Sized by
                        // height because the art is taller than it is wide.
                        Image.asset('assets/branding/mascot.png', height: 140),

                        const SizedBox(height: 28),

                        // Actions — app.js:188-198
                        Column(
                          children: [
                            SizedBox(
                              width: 220,
                              child: PrimaryButton(
                                label: 'Main Baru',
                                fontSize: 22,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                onPressed: () async {
                                  if (state.activeRun != null) {
                                    final replace = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Main baru?'),
                                        content: const Text(
                                          'Permainan tersimpan akan diganti.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, true),
                                            child: const Text('Main Baru'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (replace != true || !context.mounted) {
                                      return;
                                    }
                                  }
                                  context.read<SfxService>().click();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const GamePage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (state.activeRun != null)
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        GamePage(savedRun: state.activeRun),
                                  ),
                                ),
                                child: const Text('Lanjutkan'),
                              ),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CollectionPage(),
                                ),
                              ),
                              child: const Text('Koleksi & Pencapaian'),
                            ),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 18,
                              runSpacing: 12,
                              children: [
                                _MenuLink(
                                  icon: Icons.settings_rounded,
                                  label: 'Pengaturan',
                                  onTap: () {
                                    context.read<SfxService>().click();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const SettingsPage(),
                                      ),
                                    );
                                  },
                                ),
                                _MenuLink(
                                  icon: Icons.leaderboard_rounded,
                                  label: 'Ranking',
                                  onTap: () {
                                    context.read<SfxService>().click();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RankingPage(),
                                      ),
                                    );
                                  },
                                ),
                                _MenuLink(
                                  icon: Icons.storefront_rounded,
                                  label: 'Toko',
                                  onTap: () {
                                    context.read<SfxService>().click();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ShopPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Port of menuLink() (app.js:131-149).
class _MenuLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.coral, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
