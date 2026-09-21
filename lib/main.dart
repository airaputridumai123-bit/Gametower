    required this.x,
    required this.y,
    required this.speed,
    this.size = 38,
  });
}

class Spell {
  double x;
  double y;
  double speed;
  double radius;

  Spell({
    required this.x,
    required this.y,
    this.speed = 600,
    this.radius = 9,
  });
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double maxLife;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
  }) : maxLife = life;
}

class _WizardGameState extends State<WizardGame>
    with SingleTickerProviderStateMixin {
  GameState state = GameState.menu;

  int hp = 3;
  int score = 0;
  int coins = 0;
  int level = 1;
  int power = 1;

  double wizardX = 40;
  double wizardY = 150;

  double gameWidth = 400;
  double gameHeight = 400;

  double joyX = 0;
  double joyY = 0;

  bool shieldActive = false;
  double shieldTime = 0;

  bool soundOn = true;

  double spawnTimer = 0;
  double animation = 0;

  Timer? timer;
  DateTime lastTime = DateTime.now();

  final Random random = Random();

  final List<Enemy> enemies = [];
  final List<Spell> spells = [];
  final List<Particle> particles = [];

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => gameLoop(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void gameLoop() {
    final now = DateTime.now();

    double dt =
        now.difference(lastTime).inMicroseconds / 1000000;

    lastTime = now;

    if (dt > 0.1) dt = 0.1;

    if (state == GameState.playing) {
      updateGame(dt);
    }

    animation += dt;

    if (mounted) {
      setState(() {});
    }
  }

  void startGame() {
    state = GameState.playing;

    hp = 3;
    score = 0;
    coins = 0;
    level = 1;
    power = 1;

    joyX = 0;
    joyY = 0;

    shieldActive = false;
    shieldTime = 0;

    spawnTimer = 0;

    enemies.clear();
    spells.clear();
    particles.clear();

    resetWizard();

    lastTime = DateTime.now();
  }

  void resetWizard() {
    wizardX = 35;
    wizardY = gameHeight / 2 - 35;

    if (wizardY < 0) {
      wizardY = 20;
    }
  }

  void pauseGame() {
    if (state != GameState.playing) return;

    state = GameState.paused;
  }

  void resumeGame() {
    state = GameState.playing;
    lastTime = DateTime.now();
  }

  void restartGame() {
    startGame();
  }

  void backMenu() {
    state = GameState.menu;

    enemies.clear();
    spells.clear();
    particles.clear();

    joyX = 0;
    joyY = 0;
  }

  void shoot() {
    if (state != GameState.playing) return;

    spells.add(
      Spell(
        x: wizardX + 65,
        y: wizardY + 38,
      ),
    );

    createParticles(
      wizardX + 65,
      wizardY + 38,
      6,
    );
  }

  void magicBomb() {
    if (state != GameState.playing) return;
    if (coins < 20) return;

    coins -= 20;

    for (int i = enemies.length - 1; i >= 0; i--) {
      final enemy = enemies[i];

      final distance =
          (enemy.x - wizardX).abs();

      if (distance < 330) {
        createParticles(
          enemy.x,
          enemy.y,
          25,
        );

        enemies.removeAt(i);
        score += 15;
      }
    }

    updateLevel();
  }

  void lightning() {
    if (state != GameState.playing) return;
    if (coins < 30) return;

    coins -= 30;

    final amount = min(4, enemies.length);

    for (int i = 0; i < amount; i++) {
      final enemy = enemies.removeAt(0);

      createLightningParticles(
        enemy.x,
        enemy.y,
      );

      score += 20;
    }

    updateLevel();
  }

  void shield() {
    if (state != GameState.playing) return;
    if (coins < 15) return;

    coins -= 15;

    shieldActive = true;
    shieldTime = 5;

    createParticles(
      wizardX + 30,
      wizardY + 38,
      20,
    );
  }

  void upgrade() {
    if (state != GameState.playing) return;
    if (coins < 50) return;

    coins -= 50;
    power++;

    createParticles(
      wizardX + 30,
      wizardY + 30,
      30,
    );
  }

  void spawnEnemy() {
    if (gameWidth <= 0 || gameHeight <= 0) return;

    final size = 30 + random.nextDouble() * 12;

    enemies.add(
      Enemy(
        x: gameWidth + 50,
        y: 35 +
            random.nextDouble() *
                max(1, gameHeight - 100),
        speed: 70 +
            random.nextDouble() * 60 +
            level * 8,
        size: size,
      ),
    );
  }

  void createParticles(
    double x,
    double y,
    int count,
  ) {
    for (int i = 0; i < count; i++) {
      particles.add(
        Particle(
          x: x,
          y: y,
          vx: (random.nextDouble() - 0.5) * 260,
          vy: (random.nextDouble() - 0.5) * 260,
          life: 0.5 +
              random.nextDouble() * 0.4,
        ),
      );
    }
  }

  void createLightningParticles(
    double x,
    double y,
  ) {
    for (int i = 0; i < 35; i++) {
      particles.add(
        Particle(
          x: x,
          y: y,
          vx: (random.nextDouble() - 0.5) * 400,
          vy: (random.nextDouble() - 0.5) * 400,
          life: 0.8,
        ),
      );
    }
  }

  void updateLevel() {
    level = score ~/ 100 + 1;
  }

  void updateGame(double dt) {
    // ========================
    // GERAK PENYIHIR
    // ========================

    wizardX += joyX * 240 * dt;
    wizardY += joyY * 240 * dt;

    wizardX = wizardX.clamp(
      0,
      max(0, gameWidth - 70),
    );

    wizardY = wizardY.clamp(
      0,
      max(0, gameHeight - 90),
    );

    // ========================
    // SHIELD
    // ========================

    if (shieldActive) {
      shieldTime -= dt;

      if (shieldTime <= 0) {
        shieldActive = false;
      }
    }

    // ========================
    // SPAWN MONSTER
    // ========================

    spawnTimer += dt;

    final delay = max(
      0.45,
      1.3 - level * 0.05,
    );

    if (spawnTimer >= delay) {
      spawnTimer = 0;
      spawnEnemy();
    }

    // ========================
    // MAGIC
    // ========================

    for (int i = spells.length - 1; i >= 0; i--) {
      final spell = spells[i];

      spell.x += spell.speed * dt;

      if (spell.x > gameWidth + 50) {
        spells.removeAt(i);
      }
    }

    // ========================
    // MONSTER
    // ========================

    for (int i = enemies.length - 1; i >= 0; i--) {
      final enemy = enemies[i];

      enemy.x -= enemy.speed * dt;

      // Keluar layar kiri
      if (enemy.x < -60) {
        enemies.removeAt(i);

        if (!shieldActive) {
          hp--;

          if (hp <= 0) {
            gameOver();
            return;
          }
        }

        continue;
      }

      // ========================
      // TABRAKAN WIZARD
      // ========================

      if (enemy.x < wizardX + 65 &&
          enemy.x + enemy.size > wizardX &&
          enemy.y < wizardY + 70 &&
          enemy.y + enemy.size > wizardY) {
        enemies.removeAt(i);

        if (!shieldActive) {
          hp--;

          createParticles(
            wizardX + 30,
            wizardY + 35,
            15,
          );

          if (hp <= 0) {
            gameOver();
            return;
          }
        } else {
          createParticles(
            enemy.x,
            enemy.y,
            20,
          );
        }

        continue;
      }

      // ========================
      // KENA MAGIC
      // ========================

      for (int j = spells.length - 1; j >= 0; j--) {
        final spell = spells[j];

        if (spell.x > enemy.x &&
            spell.x <
                enemy.x + enemy.size &&
            spell.y > enemy.y &&
            spell.y <
                enemy.y + enemy.size) {
          createParticles(
            enemy.x + enemy.size / 2,
            enemy.y + enemy.size / 2,
            20,
          );

          enemies.removeAt(i);
          spells.removeAt(j);

          score += 10 * power;
          coins += 5;

          updateLevel();

          break;
        }
      }
    }

    // ========================
    // PARTICLES
    // ========================

    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];

      p.x += p.vx * dt;
      p.y += p.vy * dt;

      p.vx *= 0.97;
      p.vy *= 0.97;

      p.life -= dt;

      if (p.life <= 0) {
        particles.removeAt(i);
      }
    }
  }

  void gameOver() {
    state = GameState.gameOver;

    joyX = 0;
    joyY = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090512),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 68,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  gameWidth =
                      constraints.maxWidth;
                  gameHeight =
                      constraints.maxHeight;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GamePainter(
                            wizardX: wizardX,
                            wizardY: wizardY,
                            shieldActive:
                                shieldActive,
                            shieldTime:
                                shieldTime,
                            enemies: enemies,
                            spells: spells,
                            particles: particles,
                            animation: animation,
                          ),
                        ),
                      ),

                      buildTopBar(),

                      if (state ==
                          GameState.menu)
                        buildMenu(),

                      if (state ==
                          GameState.paused)
                        buildPause(),

                      if (state ==
                          GameState.gameOver)
                        buildGameOver(),
                    ],
                  );
                },
              ),
            ),

            Expanded(
              flex: 32,
              child: buildControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopBar() {
    return Positioned(
      top: 8,
      left: 10,
      right: 10,
      child: Row(
        children: [
          topInfo(
            "❤️",
            "$hp",
          ),
          const Spacer(),
          topInfo(
            "⭐",
            "$score",
          ),
          const Spacer(),
          topInfo(
            "💎",
            "$coins",
          ),
          const Spacer(),
          topInfo(
            "🏆",
            "LV $level",
          ),
          const SizedBox(width: 10),

          GestureDetector(
            onTap: pauseGame,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius:
                    BorderRadius.circular(9),
              ),
              child: const Text(
                "⏸️",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget topInfo(
    String icon,
    String value,
  ) {
    return Text(
      "$icon $value",
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            offset: Offset(2, 2),
            blurRadius: 2,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget buildMenu() {
    return gameOverlay(
      title: "🧙 WIZARD DEFENSE",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Jadilah penyihir hebat!\n\n"
            "🎮 Gerakkan penyihir dengan joystick\n"
            "🔮 Tembakkan sihir ke monster\n"
            "💎 Kumpulkan permata\n"
            "⬆️ Tingkatkan kekuatanmu!",
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 22),
          menuButton(
            "✨ MULAI GAME",
            const Color(0xff8e44ad),
            startGame,
          ),
        ],
      ),
    );
  }

  Widget buildPause() {
    return gameOverlay(
      title: "⏸️ PAUSE",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          menuButton(
            "▶️ LANJUT",
            const Color(0xff8e44ad),
            resumeGame,
          ),
          menuButton(
            "🔄 RESTART",
            const Color(0xff3498db),
            restartGame,
          ),
          menuButton(
            "🏠 MENU",
            const Color(0xff7f8c8d),
            backMenu,
          ),
        ],
      ),
    );
  }

  Widget buildGameOver() {
    return gameOverlay(
      title: "💀 GAME OVER",
      titleColor: Colors.redAccent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "⭐ Skor: $score\n\n"
            "💎 Permata: $coins\n\n"
            "🏆 Level: $level",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          menuButton(
            "🔄 MAIN LAGI",
            const Color(0xff3498db),
            restartGame,
          ),
          menuButton(
            "🏠 MENU",
            const Color(0xff7f8c8d),
            backMenu,
          ),
        ],
      ),
    );
  }

  Widget gameOverlay({
    required String title,
    required Widget child,
    Color titleColor =
        const Color(0xffd7a7ff),
  }) {
    return Positioned.fill(
      child: Container(
        color:
            Colors.black.withOpacity(0.90),
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget menuButton(
    String text,
    Color color,
    VoidCallback action,
  ) {
    return Padding(
      padding:
          const EdgeInsets.all(5),
      child: ElevatedButton(
        onPressed: action,
        style:
            ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 14,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildControls() {
    return Container(
      decoration:
          const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff15121c),
            Color(0xff292332),
          ],
          begin:
              Alignment.topCenter,
          end:
              Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          buildJoystick(),

          const SizedBox(width: 12),

          buildSkills(),

          const SizedBox(width: 12),

          buildShootButton(),
        ],
      ),
    );
  }

  Widget buildJoystick() {
    return GestureDetector(
      onPanUpdate: (details) {
        updateJoystick(
          details.localPosition,
        );
      },
      onPanEnd: (_) {
        joyX = 0;
        joyY = 0;
      },
      child: Container(
        width: 115,
        height: 115,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              const RadialGradient(
            colors: [
              Color(0xff514765),
              Color(0xff30293a),
              Color(0xff15121b),
            ],
            stops: [
              .35,
              .70,
              1,
            ],
          ),
          border: Border.all(
            color:
                const Color(0xff695c78),
            width: 4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Center(
          child: Transform.translate(
            offset: Offset(
              joyX * 28,
              joyY * 28,
            ),
            child: Container(
              width: 55,
              height: 55,
              decoration:
                  const BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    RadialGradient(
                  colors: [
                    Color(0xffa98fc2),
                    Color(0xff48375b),
                  ],
                  center:
                      Alignment(-.4, -.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void updateJoystick(
    Offset position,
  ) {
    const center =
        Offset(57.5, 57.5);

    double x =
        position.dx - center.dx;

    double y =
        position.dy - center.dy;

    final distance =
        sqrt(x * x + y * y);

    if (distance > 35) {
      x =
          x / distance * 35;
      y =
          y / distance * 35;
    }

    joyX = x / 35;
    joyY = y / 35;
  }

  Widget buildSkills() {
    return SizedBox(
      width: 125,
      height: 125,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        physics:
            const NeverScrollableScrollPhysics(),
        children: [
          skill(
            "💥",
            "BOM",
            magicBomb,
          ),
          skill(
            "⚡",
            "PETIR",
            lightning,
          ),
          skill(
            "🛡️",
            "PERISAI",
            shield,
          ),
          skill(
            "⬆️",
            "UPGRADE",
            upgrade,
          ),
        ],
      ),
    );
  }

  Widget skill(
    String icon,
    String text,
    VoidCallback action,
  ) {
    return GestureDetector(
      onTap: action,
      child: Container(
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(15),
          gradient:
              const LinearGradient(
            colors: [
              Color(0xff49345a),
              Color(0xff19151e),
            ],
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
          ),
          border: Border.all(
            color:
                const Color(0xff70518a),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style:
                  const TextStyle(
                fontSize: 22,
              ),
            ),
            Text(
              text,
              style:
                  const TextStyle(
                fontSize: 7,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildShootButton() {
    return GestureDetector(
      onTap: shoot,
      child: Container(
        width: 115,
        height: 115,
        decoration:
            const BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              RadialGradient(
            colors: [
              Color(0xffe8bfff),
              Color(0xff9b59b6),
              Color(0xff51266b),
            ],
            center:
                Alignment(-.4, -.5),
          ),
          border: Border.fromBorderSide(
            BorderSide(
              color:
                  Color(0xffc39bd3),
              width: 5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Color(0xff3d174d),
              offset:
                  Offset(0, 8),
            ),
            BoxShadow(
              color:
                  Color(0xff9b59b6),
              blurRadius: 25,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "🔮\nSIHIR",
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class WizardGame extends StatefulWidget {
  const WizardGame({super.key});

  @override
  State<WizardGame> createState() =>
      _WizardGameState();
}


/* ================================================= */
/* ================= GAME PAINTER ================== */
/* ================================================= */

class GamePainter extends CustomPainter {
  final double wizardX;
  final double wizardY;

  final bool shieldActive;
  final double shieldTime;

  final List<Enemy> enemies;
  final List<Spell> spells;
  final List<Particle> particles;

  final double animation;

  GamePainter({
    required this.wizardX,
    required this.wizardY,
    required this.shieldActive,
    required this.shieldTime,
    required this.enemies,
    required this.spells,
    required this.particles,
    required this.animation,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    drawBackground(
      canvas,
      size,
    );

    drawMagicStars(
      canvas,
      size,
    );

    drawWizard(canvas);

    drawSpells(canvas);

    drawEnemies(canvas);

    drawParticles(canvas);
  }

  void drawBackground(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..shader =
          const LinearGradient(
        colors: [
          Color(0xff100820),
          Color(0xff261747),
          Color(0xff173d2d),
        ],
        begin:
            Alignment.topCenter,
        end:
            Alignment.bottomCenter,
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
      paint,
    );

    // BULAN
    final moonPaint = Paint()
      ..color =
          const Color(0xffeee7ff);

    canvas.drawCircle(
      Offset(
        size.width - 55,
        60,
      ),
      25,
      moonPaint,
    );

    final shadowPaint = Paint()
      ..color =
          const Color(0xff261747);

    canvas.drawCircle(
      Offset(
        size.width - 43,
        52,
      ),
      23,
      shadowPaint,
    );

    // TANAH
    final ground =
        Paint()
          ..color =
              const Color(0xff287a46);

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height - 25,
        size.width,
        25,
      ),
      ground,
    );
  }

  void drawMagicStars(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color =
          Colors.white;

    for (int i = 0; i < 35; i++) {
      final x =
          (i * 97.0) %
              size.width;

      final y =
          (i * 43.0) %
              max(
                1,
                size.height - 70,
              );

      final pulse =
          sin(
            animation * 3 + i,
          );

      final r =
          1 + pulse.abs();

      canvas.drawCircle(
        Offset(x, y),
        r,
        paint,
      );
    }
  }

  void drawWizard(
    Canvas canvas,
  ) {
    final x = wizardX;
    final y = wizardY;

    final paint = Paint();

    // CAPE
    paint.color =
        const Color(0xff71368a);

    final robe = Path();

    robe.moveTo(
      x + 5,
      y + 72,
    );

    robe.lineTo(
      x + 50,
      y + 72,
    );

    robe.lineTo(
      x + 41,
      y + 28,
    );

    robe.lineTo(
      x + 15,
      y + 28,
    );

    robe.close();

    canvas.drawPath(
      robe,
      paint,
    );

    // SABUK
    paint.color =
        const Color(0xffffd43b);

    canvas.drawRect(
      Rect.fromLTWH(
        x + 14,
        y + 48,
        27,
        5,
      ),
      paint,
    );

    // KEPALA
    paint.color =
        const Color(0xffffd0a8);

    canvas.drawCircle(
      Offset(
        x + 28,
        y + 25,
      ),
      15,
      paint,
    );

    // RAMBUT
    paint.color =
        const Color(0xff24152e);

    canvas.drawCircle(
      Offset(
        x + 18,
        y + 18,
      ),
      7,
      paint,
    );

    canvas.drawCircle(
      Offset(
        x + 38,
        y + 18,
      ),
      7,
      paint,
    );

    // TOPI
    paint.color =
        const Color(0xff4a235a);

    final hat = Path();

    hat.moveTo(
      x + 5,
      y + 18,
    );

    hat.lineTo(
      x + 50,
      y + 18,
    );

    hat.lineTo(
      x + 28,
      y - 20,
    );

    hat.close();

    canvas.drawPath(
      hat,
      paint,
    );

    // PITA
    paint.color =
        const Color(0xffffd43b);

    canvas.drawRect(
      Rect.fromLTWH(
        x + 13,
        y + 12,
        30,
        5,
      ),
      paint,
    );

    // MATA
    paint.color =
        Colors.black;

    canvas.drawCircle(
      Offset(
        x + 22,
        y + 25,
      ),
      2,
      paint,
    );

    canvas.drawCircle(
      Offset(
        x + 34,
        y + 25,
      ),
      2,
      paint,
    );

    // SENYUM
    paint
      ..color =
          Colors.black
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 2;

    final smile =
        Path();

    smile.moveTo(
      x + 23,
      y + 32,
    );

    smile.quadraticBezierTo(
      x + 28,
      y + 36,
      x + 34,
      y + 32,
    );

    canvas.drawPath(
      smile,
      paint,
    );

    paint.style =
        PaintingStyle.fill;

    // TANGAN
    paint.color =
        const Color(0xffffd0a8);

    canvas.drawCircle(
      Offset(
        x + 3,
        y + 43,
      ),
      7,
      paint,
    );

    canvas.drawCircle(
      Offset(
        x + 53,
        y + 43,
      ),
      7,
      paint,
    );

    // TONGKAT
    paint
      ..color =
          const Color(0xff8e5a2a)
      ..strokeWidth = 4;

    canvas.drawLine(
      Offset(
        x + 54,
        y + 70,
      ),
      Offset(
        x + 62,
        y + 12,
      ),
      paint,
    );

    // PERMATA TONGKAT
    paint.color =
        const Color(0xff00e5ff);

    canvas.drawCircle(
      Offset(
        x + 63,
        y + 10,
      ),
      8,
      paint,
    );

    // CAHAYA TONGKAT
    paint
      ..color =
          const Color(0xff00e5ff)
              .withOpacity(0.25)
      ..maskFilter =
          const MaskFilter.blur(
        BlurStyle.normal,
        12,
      );

    canvas.drawCircle(
      Offset(
        x + 63,
        y + 10,
      ),
      12,
      paint,
    );

    // SHIELD
    if (shieldActive) {
      final pulse =
          sin(animation * 7) * 4;

      paint
        ..color =
            const Color(0xff00e5ff)
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 5;

      canvas.drawCircle(
        Offset(
          x + 28,
          y + 38,
        ),
        55 + pulse,
        paint,
      );

      paint
        ..color =
            const Color(0xff00e5ff)
                .withOpacity(0.12)
        ..style =
            PaintingStyle.fill;

      canvas.drawCircle(
        Offset(
          x + 28,
          y + 38,
        ),
        53 + pulse,
        paint,
      );

      // WAKTU SHIELD
      final textPainter =
          TextPainter(
        text: TextSpan(
          text:
              shieldTime.ceil()
                  .toString(),
          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        textDirection:
            TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          x + 22,
          y - 35,
        ),
      );
    }
  }

  void drawSpells(
    Canvas canvas,
  ) {
    for (final spell in spells) {
      final glow =
          Paint()
            ..color =
                const Color(0xffc77dff)
            ..maskFilter =
                const MaskFilter.blur(
              BlurStyle.normal,
              12,
            );

      canvas.drawCircle(
        Offset(
          spell.x,
          spell.y,
        ),
        15,
        glow,
      );

      final paint =
          Paint()
            ..color =
                const Color(0xffe3a7ff);

      canvas.drawCircle(
        Offset(
          spell.x,
          spell.y,
        ),
        spell.radius,
        paint,
      );

      paint.color =
          Colors.white;

      canvas.drawCircle(
        Offset(
          spell.x - 3,
          spell.y - 3,
        ),
        3,
        paint,
      );
    }
  }

  void drawEnemies(
    Canvas canvas,
  ) {
    for (final enemy in enemies) {
      final x = enemy.x;
      final y = enemy.y;
      final s = enemy.size;

      final paint = Paint()
        ..color =
            const Color(0xffe74c3c);

      // BADAN
      final body =
          RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          y,
          s,
          s,
        ),
        const Radius.circular(9),
      );

      canvas.drawRRect(
        body,
        paint,
      );

      // TELINGA
      paint.color =
          const Color(0xffc0392b);

      canvas.drawCircle(
        Offset(
          x + 5,
          y + 5,
        ),
        7,
        paint,
      );

      canvas.drawCircle(
        Offset(
          x + s - 5,
          y + 5,
        ),
        7,
        paint,
      );

      // MATA
      paint.color =
          Colors.white;

      canvas.drawCircle(
        Offset(
          x + s * .3,
          y + s * .35,
        ),
        5,
        paint,
      );

      canvas.drawCircle(
        Offset(
          x + s * .7,
          y + s * .35,
        ),
        5,
        paint,
      );

      // PUPIL
      paint.color =
          Colors.black;

      canvas.drawCircle(
        Offset(
          x + s * .3,
          y + s * .35,
        ),
        2,
        paint,
      );

      canvas.drawCircle(
        Offset(
          x + s * .7,
          y + s * .35,
        ),
        2,
        paint,
      );

      // MULUT
      paint.color =
          Colors.black;

      canvas.drawOval(
        Rect.fromLTWH(
          x + s * .25,
          y + s * .62,
          s * .5,
          s * .16,
        ),
        paint,
      );

      // TANDA MONSTER
      paint.color =
          const Color(0xffffc107);

      canvas.drawCircle(
        Offset(
          x + s / 2,
          y + s * .55,
        ),
        2,
        paint,
      );
    }
  }

  void drawParticles(
    Canvas canvas,
  ) {
    for (final p in particles) {
      final opacity =
          (p.life / p.maxLife)
              .clamp(0.0, 1.0);

      final paint =
          Paint()
            ..color =
                Color.fromRGBO(
              217,
              140,
              255,
              opacity,
            );

      canvas.drawCircle(
        Offset(
          p.x,
          p.y,
        ),
        3 + opacity * 3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant GamePainter oldDelegate,
  ) {
    return true;
  }
}
