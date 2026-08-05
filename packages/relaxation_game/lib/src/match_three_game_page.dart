import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'match_three_controller.dart';

class AnimalMatchGamePage extends StatelessWidget {
  const AnimalMatchGamePage({super.key, this.title = '동물 팡팡', this.controller});

  final String title;
  final MatchThreeController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        foregroundColor: const Color(0xFF1F2937),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: AnimalMatchGame(controller: controller),
    );
  }
}

class AnimalMatchGame extends StatefulWidget {
  const AnimalMatchGame({super.key, this.controller});

  final MatchThreeController? controller;

  @override
  State<AnimalMatchGame> createState() => _AnimalMatchGameState();
}

class _AnimalMatchGameState extends State<AnimalMatchGame> {
  late final MatchThreeController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? MatchThreeController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6FAFD), Color(0xFFEAF5FD), Color(0xFFF6FAFD)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 100,
                left: -60,
                child: _GlowOrb(size: 190, color: Color(0x3366B5F8)),
              ),
              const Positioned(
                top: 330,
                right: -70,
                child: _GlowOrb(size: 210, color: Color(0x3369D5B1)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 58, 14, 14),
                  child: Column(
                    children: [
                      _TopHud(controller: _controller),
                      const SizedBox(height: 12),
                      _GoalBar(controller: _controller),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _AnimalBoard(controller: _controller),
                                _ComboBurst(controller: _controller),
                                if (_controller.isGameOver)
                                  _GameOverOverlay(controller: _controller),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _BottomControls(controller: _controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({required this.controller});

  final MatchThreeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HudPill(
          icon: Icons.star_rounded,
          label: 'SCORE',
          value: '${controller.score}',
          color: const Color(0xFFF2B84B),
        ),
        const SizedBox(width: 8),
        _MovesBadge(moves: controller.movesLeft),
        const SizedBox(width: 8),
        _HudPill(
          icon: Icons.bolt_rounded,
          label: 'COMBO',
          value: 'x${controller.bestCombo}',
          color: const Color(0xFF69D5B1),
        ),
      ],
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E7EC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 5),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovesBadge extends StatelessWidget {
  const _MovesBadge({required this.moves});

  final int moves;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF7CC6FA), Color(0xFF2F80C9)],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x5566B5F8), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'MOVES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '$moves',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.controller});

  final MatchThreeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                '🏆  GOAL',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${controller.score} / ${MatchThreeController.goalScore}',
                style: const TextStyle(
                  color: Color(0xFF2F80C9),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6FA),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: constraints.maxWidth * controller.goalProgress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66B5F8), Color(0xFF69D5B1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x5566B5F8), blurRadius: 8),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RecordValue(
                icon: Icons.workspace_premium_rounded,
                label: controller.isLoadingRecords
                    ? '최고 기록 -'
                    : '최고 기록 ${controller.highScore}',
              ),
              _RecordValue(
                icon: Icons.bolt_rounded,
                label: '최고 콤보 x${controller.highCombo}',
              ),
              _RecordValue(
                icon: Icons.sports_esports_rounded,
                label: '${controller.gamesPlayed}회 플레이',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordValue extends StatelessWidget {
  const _RecordValue({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF2F80C9)),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AnimalBoard extends StatelessWidget {
  const _AnimalBoard({required this.controller});

  final MatchThreeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF86CDFB), Color(0xFF2F80C9)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(color: Color(0x5566B5F8), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: AbsorbPointer(
        absorbing: controller.isResolving,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              MatchThreeController.boardSize * MatchThreeController.boardSize,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MatchThreeController.boardSize,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final position = BoardPosition(
              index ~/ MatchThreeController.boardSize,
              index % MatchThreeController.boardSize,
            );
            return _AnimalTileWidget(
              key: ValueKey('tile-$index'),
              tile: controller.tileAt(position),
              selected: controller.selected == position,
              clearing: controller.clearingPositions.contains(position),
              onTap: () => controller.selectTile(position),
            );
          },
        ),
      ),
    );
  }
}

class _AnimalTileWidget extends StatelessWidget {
  const _AnimalTileWidget({
    super.key,
    required this.tile,
    required this.selected,
    required this.clearing,
    required this.onTap,
  });

  final AnimalTile? tile;
  final bool selected;
  final bool clearing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _tileColors(tile);
    return Semantics(
      button: tile != null,
      selected: selected,
      label: tile == null ? '빈칸' : '${tile!.name} 타일',
      child: GestureDetector(
        onTap: tile == null ? null : onTap,
        child: AnimatedScale(
          scale: clearing ? 0.15 : (selected ? 1.12 : 1),
          duration: const Duration(milliseconds: 180),
          curve: clearing ? Curves.easeInBack : Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: clearing ? 0 : 1,
            duration: const Duration(milliseconds: 160),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  width: selected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0xAAFFFFFF)
                        : const Color(0x55000000),
                    blurRadius: selected ? 10 : 3,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: tile == null
                    ? const SizedBox.shrink(key: ValueKey('empty'))
                    : FittedBox(
                        key: ValueKey(tile),
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tile!.emoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _tileColors(AnimalTile? tile) => switch (tile) {
    AnimalTile.puppy => const [Color(0xFFFFD65B), Color(0xFFFF9E3D)],
    AnimalTile.kitten => const [Color(0xFFFF8FB8), Color(0xFFFF5E84)],
    AnimalTile.bunny => const [Color(0xFFE9A8FF), Color(0xFFB96EF1)],
    AnimalTile.bear => const [Color(0xFFD89B6C), Color(0xFFA85E46)],
    AnimalTile.panda => const [Color(0xFFE9F4FF), Color(0xFFAFC6DD)],
    AnimalTile.fox => const [Color(0xFFFFA45B), Color(0xFFF35D48)],
    null => const [Color(0x3366B5F8), Color(0x3366B5F8)],
  };
}

class _ComboBurst extends StatelessWidget {
  const _ComboBurst({required this.controller});

  final MatchThreeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.feedbackSerial == 0 || controller.lastScoreGain == 0) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(controller.feedbackSerial),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 750),
          builder: (context, value, child) {
            final opacity = math.sin(math.pi * value).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, -55 * value),
                child: Transform.scale(
                  scale: 0.7 + (0.5 * math.sin(math.pi * value)),
                  child: child,
                ),
              ),
            );
          },
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF69D5B1), Color(0xFF66B5F8)],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x7766B5F8),
                    blurRadius: 22,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Text(
                controller.lastCombo > 1
                    ? '${controller.lastCombo} COMBO!  +${controller.lastScoreGain}'
                    : 'POP!  +${controller.lastScoreGain}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.controller});

  final MatchThreeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GameButton(
            icon: Icons.casino_rounded,
            label: '섞기',
            colors: const [Color(0xFF7CC6FA), Color(0xFF2F80C9)],
            onPressed: controller.isGameOver || controller.isResolving
                ? null
                : controller.shuffle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GameButton(
            icon: Icons.refresh_rounded,
            label: '새 게임',
            colors: const [Color(0xFF7ADDBD), Color(0xFF32B768)],
            onPressed: controller.isResolving ? null : controller.newGame,
          ),
        ),
      ],
    );
  }
}

class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.controller});

  final MatchThreeController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xE02F80C9),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF69D5B1), width: 3),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.reachedGoal ? '🏆' : '⭐',
                style: const TextStyle(fontSize: 54),
              ),
              Text(
                controller.reachedGoal ? 'MISSION CLEAR!' : 'NICE PLAY!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'FINAL SCORE  ${controller.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: controller.newGame,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('PLAY AGAIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
