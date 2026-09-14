import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio/sfx_service.dart';
import '../audio/vibration_service.dart';
import '../models/skin_data.dart';
import '../state/app_state.dart';
import '../game/fruit_sprites.dart';
import '../widgets/app_back_button.dart';
import 'theme.dart';

/// Port of buildShopScreen() + renderShopGrid() (app.js:349-429).
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  /// Every card draws its own skin, so all of them have to be decoded — not
  /// just the equipped one. Held in a field rather than built inline: this
  /// page rebuilds on every coin change, and a fresh future each time would
  /// restart the decode over and over.
  late final Future<void> _artworkReady =
      Future.wait(kSkins.map((sk) => FruitSprites.ensureLoaded(sk.id)));

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppBackButton(onTap: () {
                    context.read<SfxService>().click();
                    Navigator.of(context).pop();
                  }),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Shop', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
                  ),
                  _CoinPill(coins: appState.coins),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<void>(
                  future: _artworkReady,
                  builder: (context, snapshot) => GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                    // Cards lay out either way; until the artwork lands their
                    // previews are simply blank, which beats holding the whole
                    // page back on a decode.
                    children: kSkins.map((sk) => _ShopCard(skin: sk)).toList(),
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

class _CoinPill extends StatelessWidget {
  final int coins;
  const _CoinPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CF),
        border: Border.all(color: const Color(0xFFFFD65C)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFE08A), Color(0xFFF4B400)]),
            ),
          ),
          const SizedBox(width: 6),
          Text('$coins', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8A6D1A))),
        ],
      ),
    );
  }
}

class _ShopCard extends StatefulWidget {
  final SkinData skin;
  const _ShopCard({required this.skin});

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    // Port of shake()/@keyframes bought (app.js:378-382, style.css:314).
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _playShake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final sk = widget.skin;
    final owned = appState.ownedSkins.contains(sk.id);
    final isEquipped = appState.equippedSkin == sk.id;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final scale = t == 0 ? 1.0 : 1.0 + 0.08 * (t < 0.4 ? (t / 0.4) : (1 - (t - 0.4) / 0.6));
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SkinPreview(skin: sk),
            const SizedBox(height: 8),
            Text(sk.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            if (isEquipped)
              _Badge(text: 'Equipped', bg: const Color(0xFFDFF3D8), fg: const Color(0xFF4C9A3A))
            else if (owned)
              _EquipButton(onTap: () {
                context.read<SfxService>().click();
                appState.equipSkin(sk.id);
                FruitSprites.use(sk.id);
              })
            else
              _LockButton(
                price: sk.price,
                affordable: appState.coins >= sk.price,
                onTap: () {
                  if (appState.coins < sk.price) {
                    context.read<SfxService>().click();
                    _playShake();
                  } else {
                    appState.buySkin(sk.id, sk.price);
                    // buySkin equips what it just sold, so the artwork has to
                    // follow it.
                    FruitSprites.use(sk.id);
                    context.read<SfxService>().buy();
                    doVibrate(appState, 20);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Shop card icon: a few of the skin's fruits overlapping, which shows off
/// the artwork better than a single fruit would.
class _SkinPreview extends StatelessWidget {
  final SkinData skin;
  const _SkinPreview({required this.skin});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 72,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(left: 0, bottom: 0, child: FruitImage(index: 0, size: 34, skin: skin.id)),
          Positioned(right: 0, bottom: 0, child: FruitImage(index: 3, size: 38, skin: skin.id)),
          Positioned(bottom: 6, child: FruitImage(index: 9, size: 48, skin: skin.id)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Badge({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _EquipButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EquipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFFFD3C4), width: 2)),
          child: const Text('Equip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.coral)),
        ),
      ),
    );
  }
}

class _LockButton extends StatelessWidget {
  final int price;
  final bool affordable;
  final VoidCallback onTap;
  const _LockButton({required this.price, required this.affordable, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: affordable ? const Color(0xFFFFF3CF) : const Color(0xFFF3EEE4),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 12, color: AppColors.label),
              const SizedBox(width: 6),
              Text('$price', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
