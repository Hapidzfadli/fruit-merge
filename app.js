(function () {
  const { createFruitEl, applyStyle, el } = window.FruitUI;
  const { SFX, startMusic, stopMusic, vibrate } = window.GameAudio;

  const FRUITS = [
    { name: 'Ceri', size: 28, colorA: '#FF8FA3', colorB: '#E63950', topper: 'none' },
    { name: 'Stroberi', size: 36, colorA: '#FF7A8A', colorB: '#E8425A', topper: 'leaf' },
    { name: 'Anggur', size: 44, colorA: '#C9A6F5', colorB: '#9B5DE0', topper: 'none' },
    { name: 'Jeruk', size: 54, colorA: '#FFC169', colorB: '#FF9F1C', topper: 'none' },
    { name: 'Apel', size: 64, colorA: '#B7E67A', colorB: '#7CB342', topper: 'none' },
    { name: 'Pir', size: 74, colorA: '#E8EA8A', colorB: '#C3D138', topper: 'none' },
    { name: 'Persik', size: 84, colorA: '#FFC1AE', colorB: '#FF8A65', topper: 'none' },
    { name: 'Nanas', size: 96, colorA: '#FFE38A', colorB: '#FBC02D', topper: 'crown' },
    { name: 'Melon', size: 108, colorA: '#D4EFA0', colorB: '#9CCC65', topper: 'none' },
    { name: 'Semangka', size: 122, colorA: '#7BC97E', colorB: '#43A047', topper: 'none' }
  ];

  const SKINS = [
    { id: 'classic', name: 'Buah Klasik', colorA: '#FFC169', colorB: '#FF9F1C', topper: 'none', price: 0 },
    { id: 'crystal', name: 'Kristal Manis', colorA: '#BEE9FF', colorB: '#4FC3F7', topper: 'none', price: 0 },
    { id: 'kawaii', name: 'Kawaii Animal', colorA: '#FFD9EC', colorB: '#FF8FC7', topper: 'leaf', price: 250 },
    { id: 'candy', name: 'Candy Pop', colorA: '#FFE9A8', colorB: '#FF6FA5', topper: 'crown', price: 400 }
  ];

  const BOARD_WIDTH = 300;
  const BOARD_HEIGHT = 460;
  const WALL = 8;
  const PW = BOARD_WIDTH - WALL * 2;
  const PH = BOARD_HEIGHT - WALL;
  const LINE_Y = 40;
  const MERGE_SCORE = [0, 20, 40, 70, 110, 160, 230, 320, 440, 600];
  const SPAWN_ANIM = 300;
  const OVER_LIMIT = 1000;
  const DROP_COOLDOWN = 320;

  const SAVE_KEY = 'fruitMergeAdventure.save';
  function loadSave() {
    try {
      const data = JSON.parse(localStorage.getItem(SAVE_KEY));
      if (!data) throw new Error('none');
      return {
        highScore: data.highScore || 0,
        coins: data.coins != null ? data.coins : 340,
        equippedSkin: data.equippedSkin || 'classic',
        ownedSkins: Array.isArray(data.ownedSkins) && data.ownedSkins.length ? data.ownedSkins : ['classic', 'crystal'],
        music: data.music !== false,
        sfx: data.sfx !== false,
        vibration: data.vibration !== false
      };
    } catch (err) {
      return { highScore: 1280, coins: 340, equippedSkin: 'classic', ownedSkins: ['classic', 'crystal'], music: true, sfx: true, vibration: true };
    }
  }
  function persist() {
    localStorage.setItem(SAVE_KEY, JSON.stringify({
      highScore: state.highScore, coins: state.coins, equippedSkin: state.equippedSkin,
      ownedSkins: state.ownedSkins, music: state.music, sfx: state.sfx, vibration: state.vibration
    }));
  }

  function randomDropIndex() { return Math.floor(Math.random() * 5); }

  const saved = loadSave();
  const state = {
    screen: 'menu',
    score: 0,
    highScore: saved.highScore,
    currentIndex: randomDropIndex(),
    nextIndex: randomDropIndex(),
    dropX: 50,
    music: saved.music,
    sfx: saved.sfx,
    vibration: saved.vibration,
    equippedSkin: saved.equippedSkin,
    ownedSkins: saved.ownedSkins,
    coins: saved.coins
  };

  const Sfx = {
    click: () => { if (state.sfx) SFX.click(); },
    drop: () => { if (state.sfx) SFX.drop(); },
    merge: (i) => { if (state.sfx) SFX.merge(i); },
    gameOver: () => { if (state.sfx) SFX.gameOver(); },
    buy: () => { if (state.sfx) SFX.buy(); }
  };
  function doVibrate(ms) { if (state.vibration) vibrate(ms); }

  // ---------------- DOM shell ----------------
  const app = document.getElementById('app');
  const phoneOuter = el('div'); phoneOuter.className = 'phone-outer';
  const phone = el('div'); phone.className = 'phone';
  const notch = el('div'); notch.className = 'notch';
  const phoneScreen = el('div'); phoneScreen.className = 'phone-screen';
  phone.appendChild(notch);
  phone.appendChild(phoneScreen);
  phoneOuter.appendChild(phone);
  app.appendChild(phoneOuter);

  function fitPhone() {
    const pad = 24;
    const availW = Math.max(240, window.innerWidth - pad * 2);
    const availH = Math.max(400, window.innerHeight - pad * 2);
    const scale = Math.min(1, availW / 375, availH / 812);
    phone.style.transform = `scale(${scale})`;
    phoneOuter.style.width = (375 * scale) + 'px';
    phoneOuter.style.height = (812 * scale) + 'px';
  }
  window.addEventListener('resize', fitPhone);
  fitPhone();

  const refs = { switches: [] };

  function backButton(onClick) {
    const btn = el('button'); btn.className = 'back-btn';
    btn.appendChild(el('div', {})).className = 'chevron';
    btn.addEventListener('click', onClick);
    return btn;
  }

  function buildSwitch(getVal, onToggle) {
    const node = el('button'); node.className = 'switch';
    const knob = el('div'); knob.className = 'knob';
    node.appendChild(knob);
    node.addEventListener('click', onToggle);
    const sw = { node, sync() { node.classList.toggle('on', !!getVal()); node.classList.toggle('off', !getVal()); } };
    sw.sync();
    return sw;
  }
  function syncSwitches() { refs.switches.forEach((sw) => sw.sync()); }

  function menuLink(kind, label, onClick) {
    const wrap = el('div'); wrap.className = 'menu-link';
    const btn = el('button'); btn.className = 'icon-btn';
    if (kind === 'settings') {
      applyStyle(btn, { flexDirection: 'column', gap: 3 });
      [20, 14, 17].forEach((w) => btn.appendChild(el('div', { width: w, height: 3, borderRadius: 2, background: '#FF6B4A' })));
    } else if (kind === 'ranking') {
      applyStyle(btn, { alignItems: 'flex-end', gap: 3 });
      [[10, '#FFC845'], [18, '#FF9F1C'], [14, '#FFC845']].forEach(([h, c]) => btn.appendChild(el('div', { width: 5, height: h, borderRadius: 2, background: c })));
    } else if (kind === 'shop') {
      applyStyle(btn, { position: 'relative' });
      btn.appendChild(el('div', { width: 20, height: 16, borderRadius: '4px 4px 8px 8px', background: '#4FC3F7' }));
      btn.appendChild(el('div', { position: 'absolute', top: 11, width: 10, height: 8, border: '2px solid #4FC3F7', borderBottom: 'none', borderRadius: '6px 6px 0 0' }));
    }
    btn.addEventListener('click', onClick);
    const label_ = el('span'); label_.textContent = label;
    wrap.appendChild(btn); wrap.appendChild(label_);
    return wrap;
  }

  function buildMascot() {
    const m = el('div'); m.className = 'mascot';
    [
      { position: 'absolute', bottom: 0, left: 20, width: 130, height: 105, background: '#A9754F', borderRadius: '50% 50% 45% 45%' },
      { position: 'absolute', bottom: 70, left: 18, width: 34, height: 34, background: '#8a5f3d', borderRadius: '50%' },
      { position: 'absolute', bottom: 72, right: 20, width: 34, height: 34, background: '#8a5f3d', borderRadius: '50%' },
      { position: 'absolute', bottom: 58, left: 38, width: 96, height: 88, background: '#C89268', borderRadius: '50%' },
      { position: 'absolute', bottom: 78, left: 56, width: 60, height: 50, background: '#EFCFA6', borderRadius: '50%' },
      { position: 'absolute', bottom: 112, left: 66, width: 11, height: 12, background: '#4A3428', borderRadius: '50%' },
      { position: 'absolute', bottom: 112, right: 66, width: 11, height: 12, background: '#4A3428', borderRadius: '50%' },
      { position: 'absolute', bottom: 98, left: 60, width: 12, height: 8, borderRadius: '50%', background: 'rgba(255,90,120,0.35)' },
      { position: 'absolute', bottom: 98, right: 60, width: 12, height: 8, borderRadius: '50%', background: 'rgba(255,90,120,0.35)' },
      { position: 'absolute', bottom: 88, left: 81, width: 18, height: 9, borderBottom: '3px solid #4A3428', borderRadius: '0 0 50% 50%' }
    ].forEach((st) => m.appendChild(el('div', st)));
    return m;
  }

  // ---------------- Menu ----------------
  function buildMenuScreen() {
    const s = el('div'); s.id = 'screen-menu'; s.className = 'screen screen-gradient';

    const d1 = createFruitEl({ size: 30, colorA: '#FF8FA3', colorB: '#E63950' });
    applyStyle(d1, { position: 'absolute', top: 60, left: 22, opacity: .85 });
    const d2 = createFruitEl({ size: 24, colorA: '#C9A6F5', colorB: '#9B5DE0' });
    applyStyle(d2, { position: 'absolute', top: 110, right: 26, opacity: .85 });
    const d3 = createFruitEl({ size: 20, colorA: '#FFC169', colorB: '#FF9F1C' });
    applyStyle(d3, { position: 'absolute', top: 160, left: 44, opacity: .7 });
    s.appendChild(d1); s.appendChild(d2); s.appendChild(d3);

    const title = el('div'); title.className = 'menu-title';
    const t1 = el('div'); t1.className = 't1'; t1.textContent = 'FRUIT MERGE';
    const t2 = el('div'); t2.className = 't2'; t2.textContent = 'ADVENTURE';
    title.appendChild(t1); title.appendChild(t2);
    s.appendChild(title);

    s.appendChild(buildMascot());

    const actions = el('div'); actions.className = 'menu-actions';
    const playBtn = el('button'); playBtn.className = 'btn-primary menu-play'; playBtn.textContent = 'PLAY';
    playBtn.addEventListener('click', () => { Sfx.click(); startGame(); });
    actions.appendChild(playBtn);

    const links = el('div'); links.className = 'menu-links';
    links.appendChild(menuLink('settings', 'Settings', () => { Sfx.click(); goSettings(); }));
    links.appendChild(menuLink('ranking', 'Ranking', () => Sfx.click()));
    links.appendChild(menuLink('shop', 'Shop', () => { Sfx.click(); goShop(); }));
    actions.appendChild(links);
    s.appendChild(actions);

    phoneScreen.appendChild(s);
    refs.menu = s;
  }

  // ---------------- Game ----------------
  function buildGameScreen() {
    const s = el('div'); s.id = 'screen-game'; s.className = 'screen screen-gradient';

    const topbar = el('div'); topbar.className = 'game-topbar';
    const pauseBtn = el('button'); pauseBtn.className = 'icon-btn';
    applyStyle(pauseBtn, { gap: 4 });
    pauseBtn.appendChild(el('div', { width: 4, height: 16, borderRadius: 2, background: '#5B4636' }));
    pauseBtn.appendChild(el('div', { width: 4, height: 16, borderRadius: 2, background: '#5B4636' }));
    pauseBtn.addEventListener('click', () => { Sfx.click(); pauseGame(); });
    topbar.appendChild(pauseBtn);

    const scorePill = el('div'); scorePill.className = 'score-pill';
    scorePill.appendChild(el('div', {})).className = 'label';
    scorePill.firstChild.textContent = 'Score';
    const scoreValue = el('div'); scoreValue.className = 'value'; scoreValue.textContent = '0';
    scorePill.appendChild(scoreValue);
    topbar.appendChild(scorePill);
    refs.scoreValue = scoreValue;

    const nextPill = el('div'); nextPill.className = 'next-pill';
    const nextLabel = el('div'); nextLabel.className = 'label'; nextLabel.textContent = 'Next';
    const nextFruitSlot = el('div');
    nextPill.appendChild(nextLabel); nextPill.appendChild(nextFruitSlot);
    topbar.appendChild(nextPill);
    refs.nextFruitSlot = nextFruitSlot;

    s.appendChild(topbar);

    const boardWrap = el('div'); boardWrap.className = 'board-wrap';
    applyStyle(boardWrap, { height: 520 });
    refs.boardWrap = boardWrap;

    const dropGuide = el('div'); dropGuide.className = 'drop-guide';
    const dropShadow = el('div'); dropShadow.className = 'drop-shadow';
    const dropPreview = el('div'); dropPreview.className = 'drop-preview';
    refs.dropGuide = dropGuide; refs.dropShadow = dropShadow; refs.dropPreview = dropPreview;

    const board = el('div'); board.className = 'board';
    const boardLine = el('div'); boardLine.className = 'board-line';
    board.appendChild(boardLine);
    refs.board = board;

    boardWrap.appendChild(dropGuide);
    boardWrap.appendChild(dropShadow);
    boardWrap.appendChild(dropPreview);
    boardWrap.appendChild(board);

    boardWrap.addEventListener('pointermove', handleBoardMove);
    boardWrap.addEventListener('click', dropFruit);

    s.appendChild(boardWrap);
    phoneScreen.appendChild(s);
    refs.game = s;
  }

  // ---------------- Pause overlay ----------------
  function buildPauseOverlay() {
    const overlay = el('div'); overlay.id = 'overlay-pause';
    const card = el('div'); card.className = 'modal-card';

    const title = el('div'); title.className = 'modal-title'; title.textContent = 'Paused';
    card.appendChild(title);

    const resumeBtn = el('button'); resumeBtn.className = 'btn-primary'; resumeBtn.textContent = 'Resume';
    resumeBtn.addEventListener('click', () => { Sfx.click(); resumeGame(); });
    card.appendChild(resumeBtn);

    const restartBtn = el('button'); restartBtn.className = 'btn-secondary'; restartBtn.textContent = 'Restart';
    restartBtn.addEventListener('click', () => { Sfx.click(); restartGame(); });
    card.appendChild(restartBtn);

    const homeBtn = el('button'); homeBtn.className = 'btn-secondary'; homeBtn.textContent = 'Home';
    homeBtn.addEventListener('click', () => { Sfx.click(); goHome(); });
    card.appendChild(homeBtn);

    const row = el('div'); row.className = 'modal-row';
    const label = el('span'); label.textContent = 'Sound';
    const sw = buildSwitch(() => state.music, () => { Sfx.click(); toggleMusic(); });
    row.appendChild(label); row.appendChild(sw.node);
    card.appendChild(row);
    refs.switches.push(sw);

    overlay.appendChild(card);
    phoneScreen.appendChild(overlay);
    refs.pauseOverlay = overlay;
  }

  // ---------------- Game over ----------------
  function buildGameOverScreen() {
    const s = el('div'); s.id = 'screen-gameover'; s.className = 'screen screen-gradient';

    const strip = el('div'); strip.className = 'fall-strip';
    [
      { left: '15%', delay: 0, size: 26, colorA: '#FF8FA3', colorB: '#E63950' },
      { left: '35%', delay: .4, size: 30, colorA: '#C9A6F5', colorB: '#9B5DE0' },
      { left: '55%', delay: .8, size: 24, colorA: '#FFC169', colorB: '#FF9F1C' },
      { left: '75%', delay: 1.2, size: 28, colorA: '#B7E67A', colorB: '#7CB342' }
    ].forEach((d) => {
      const wrap = el('div'); wrap.className = 'f';
      applyStyle(wrap, { left: d.left, animationDelay: d.delay + 's' });
      wrap.appendChild(createFruitEl({ size: d.size, colorA: d.colorA, colorB: d.colorB }));
      strip.appendChild(wrap);
    });
    s.appendChild(strip);

    const title = el('div'); title.className = 'go-title'; title.textContent = 'Game Over!';
    s.appendChild(title);

    const stats = el('div'); stats.className = 'go-stats';
    const scoreStat = el('div'); scoreStat.className = 'go-stat';
    const scoreLabel = el('div'); scoreLabel.className = 'label'; scoreLabel.textContent = 'Score';
    const scoreValue = el('div'); scoreValue.className = 'value';
    scoreStat.appendChild(scoreLabel); scoreStat.appendChild(scoreValue);
    refs.goScoreValue = scoreValue;

    const bestStat = el('div'); bestStat.className = 'go-stat';
    const bestLabel = el('div'); bestLabel.className = 'label'; bestLabel.textContent = 'Best';
    const bestValue = el('div'); bestValue.className = 'value';
    bestStat.appendChild(bestLabel); bestStat.appendChild(bestValue);
    refs.goBestValue = bestValue;

    stats.appendChild(scoreStat); stats.appendChild(bestStat);
    s.appendChild(stats);

    const coinsLine = el('div'); coinsLine.className = 'go-coins';
    refs.goCoinsLine = coinsLine;
    s.appendChild(coinsLine);

    const actions = el('div'); actions.className = 'go-actions';
    const again = el('button'); again.className = 'btn-primary'; again.textContent = 'Main Lagi';
    again.addEventListener('click', () => { Sfx.click(); restartGame(); });
    const home = el('button'); home.className = 'btn-secondary'; home.textContent = 'Home';
    home.addEventListener('click', () => { Sfx.click(); goHome(); });
    actions.appendChild(again); actions.appendChild(home);
    s.appendChild(actions);

    const ad = el('div'); ad.className = 'ad-banner'; ad.textContent = 'Ad Banner · 320×50';
    s.appendChild(ad);

    phoneScreen.appendChild(s);
    refs.gameover = s;
  }

  // ---------------- Shop ----------------
  function buildShopScreen() {
    const s = el('div'); s.id = 'screen-shop'; s.className = 'screen screen-flat';

    const header = el('div'); header.className = 'shop-header';
    header.appendChild(backButton(() => { Sfx.click(); goHome(); }));
    const title = el('div'); title.className = 'shop-title'; title.textContent = 'Shop';
    header.appendChild(title);

    const coinDot = el('div'); coinDot.className = 'coin-dot';
    const coinValue = el('span'); coinValue.textContent = String(state.coins);
    const coinPill = el('div'); coinPill.className = 'coin-pill';
    coinPill.appendChild(coinDot); coinPill.appendChild(coinValue);
    header.appendChild(coinPill);
    refs.shopCoinValue = coinValue;

    s.appendChild(header);

    const grid = el('div'); grid.className = 'shop-grid';
    refs.shopGrid = grid;
    s.appendChild(grid);

    phoneScreen.appendChild(s);
    refs.shop = s;
  }

  function updateCoinDisplays() {
    if (refs.shopCoinValue) refs.shopCoinValue.textContent = String(state.coins);
  }

  function shake(node) {
    node.style.animation = 'none';
    void node.offsetWidth;
    node.style.animation = 'bought .5s ease';
  }

  function renderShopGrid() {
    refs.shopGrid.innerHTML = '';
    SKINS.forEach((sk) => {
      const owned = state.ownedSkins.includes(sk.id);
      const isEquipped = state.equippedSkin === sk.id;
      const card = el('div'); card.className = 'shop-card';
      card.appendChild(createFruitEl({ size: 60, colorA: sk.colorA, colorB: sk.colorB, topper: sk.topper }));
      const name = el('div'); name.className = 'name'; name.textContent = sk.name;
      card.appendChild(name);

      if (isEquipped) {
        const badge = el('div'); badge.className = 'shop-badge-equipped'; badge.textContent = 'Equipped';
        card.appendChild(badge);
      } else if (owned) {
        const btn = el('button'); btn.className = 'shop-btn-equip'; btn.textContent = 'Equip';
        btn.addEventListener('click', () => {
          Sfx.click();
          state.equippedSkin = sk.id;
          persist();
          renderShopGrid();
        });
        card.appendChild(btn);
      } else {
        const affordable = state.coins >= sk.price;
        const lockBtn = el('button'); lockBtn.className = 'shop-locked' + (affordable ? ' affordable' : '');
        const lockIcon = el('div'); lockIcon.className = 'lock-icon';
        lockIcon.appendChild(el('div', {})).className = 'shackle';
        lockIcon.appendChild(el('div', {})).className = 'body';
        const priceLabel = el('span'); priceLabel.textContent = String(sk.price);
        lockBtn.appendChild(lockIcon); lockBtn.appendChild(priceLabel);
        lockBtn.addEventListener('click', () => {
          if (state.coins < sk.price) { Sfx.click(); shake(card); return; }
          state.coins -= sk.price;
          state.ownedSkins.push(sk.id);
          state.equippedSkin = sk.id;
          Sfx.buy();
          doVibrate(20);
          persist();
          renderShopGrid();
          updateCoinDisplays();
        });
        card.appendChild(lockBtn);
      }
      refs.shopGrid.appendChild(card);
    });
  }

  // ---------------- Settings ----------------
  function buildSettingsScreen() {
    const s = el('div'); s.id = 'screen-settings'; s.className = 'screen screen-flat';

    const header = el('div'); header.className = 'settings-header';
    header.appendChild(backButton(() => { Sfx.click(); goHome(); }));
    const title = el('div'); title.className = 'settings-title'; title.textContent = 'Settings';
    header.appendChild(title);
    s.appendChild(header);

    const list = el('div'); list.className = 'settings-list';

    const rows = [
      ['Music', () => state.music, () => { Sfx.click(); toggleMusic(); }],
      ['SFX', () => state.sfx, () => { toggleSfx(); Sfx.click(); }],
      ['Vibration', () => state.vibration, () => { Sfx.click(); toggleVibration(); }]
    ];
    rows.forEach(([label, getVal, onToggle]) => {
      const row = el('div'); row.className = 'settings-row';
      const span = el('span'); span.textContent = label;
      const sw = buildSwitch(getVal, onToggle);
      row.appendChild(span); row.appendChild(sw.node);
      list.appendChild(row);
      refs.switches.push(sw);
    });
    s.appendChild(list);

    const actions = el('div'); actions.className = 'settings-actions';
    const privacy = el('button'); privacy.className = 'btn-secondary'; privacy.textContent = 'Privacy Policy';
    privacy.addEventListener('click', () => Sfx.click());
    const rate = el('button'); rate.className = 'btn-secondary'; rate.textContent = 'Rate Us';
    rate.addEventListener('click', () => Sfx.click());
    actions.appendChild(privacy); actions.appendChild(rate);
    s.appendChild(actions);

    phoneScreen.appendChild(s);
    refs.settings = s;
  }

  // ---------------- Navigation ----------------
  function renderScreenVisibility() {
    const gameLike = state.screen === 'game' || state.screen === 'pause';
    refs.menu.classList.toggle('active', state.screen === 'menu');
    refs.game.classList.toggle('active', gameLike);
    refs.gameover.classList.toggle('active', state.screen === 'gameover');
    refs.shop.classList.toggle('active', state.screen === 'shop');
    refs.settings.classList.toggle('active', state.screen === 'settings');
    refs.pauseOverlay.classList.toggle('active', state.screen === 'pause');
  }

  function goHome() { stopMusic(); state.screen = 'menu'; renderScreenVisibility(); }
  function goShop() { renderShopGrid(); updateCoinDisplays(); state.screen = 'shop'; renderScreenVisibility(); }
  function goSettings() { state.screen = 'settings'; renderScreenVisibility(); }
  function pauseGame() { stopMusic(); state.screen = 'pause'; renderScreenVisibility(); }
  function resumeGame() { state.screen = 'game'; if (state.music) startMusic(); renderScreenVisibility(); }

  function toggleMusic() {
    state.music = !state.music;
    if (state.music && state.screen === 'game') startMusic(); else stopMusic();
    persist();
    syncSwitches();
  }
  function toggleSfx() { state.sfx = !state.sfx; persist(); syncSwitches(); }
  function toggleVibration() { state.vibration = !state.vibration; persist(); syncSwitches(); }

  // ---------------- Physics ----------------
  let engine = null;
  let raf = null;
  let lastDrop = 0;
  const bodyEls = new Map();

  function initPhysics() {
    const M = window.Matter;
    engine = M.Engine.create();
    engine.gravity.y = 1.9;
    engine.positionIterations = 14;
    engine.velocityIterations = 12;
    engine.constraintIterations = 4;
    const wallOpts = { isStatic: true, friction: 0.75, frictionStatic: 0.9, restitution: 0 };
    M.Composite.add(engine.world, [
      M.Bodies.rectangle(PW / 2, PH + 40, PW + 200, 80, wallOpts),
      M.Bodies.rectangle(-40, PH / 2, 80, PH * 3, wallOpts),
      M.Bodies.rectangle(PW + 40, PH / 2, 80, PH * 3, wallOpts)
    ]);
    M.Events.on(engine, 'collisionStart', (ev) => {
      for (const pair of ev.pairs) {
        const a = pair.bodyA, b = pair.bodyB;
        if (!a.plugin || !b.plugin || a.plugin.dead || b.plugin.dead) continue;
        if (a.plugin.index !== b.plugin.index) continue;
        if (a.plugin.index >= FRUITS.length - 1) continue;
        a.plugin.dead = true; b.plugin.dead = true;
        mergeBodies(a, b);
      }
    });
  }

  function fruitBodies() {
    if (!engine) return [];
    return window.Matter.Composite.allBodies(engine.world).filter((b) => b.plugin && b.plugin.isFruit && !b.plugin.dead);
  }

  function spawnFruit(index, x, y, extra) {
    const M = window.Matter;
    const f = FRUITS[index];
    const r = f.size / 2;
    const body = M.Bodies.circle(x, y, r, {
      restitution: index <= 2 ? 0.16 : Math.max(0.02, 0.14 - index * 0.02),
      friction: index <= 2 ? 0.42 : 0.58,
      frictionStatic: 0.5,
      frictionAir: 0.004,
      density: 0.0012,
      slop: 0.02,
      sleepThreshold: Infinity
    });
    body.plugin = { isFruit: true, index, spawnAt: performance.now(), flash: extra && extra.flash ? 1 : 0, overMs: 0, dead: false };
    if (extra && extra.vy !== undefined) M.Body.setVelocity(body, { x: extra.vx || 0, y: extra.vy });
    M.Body.setAngularVelocity(body, (Math.random() - 0.5) * 0.06);
    M.Composite.add(engine.world, body);
    return body;
  }

  function postStep(now) {
    const M = window.Matter;
    for (const b of fruitBodies()) {
      const speed = Math.hypot(b.velocity.x, b.velocity.y);
      M.Body.setAngularVelocity(b, b.angularVelocity * (speed < 0.35 ? 0.55 : 0.9));
      if (speed < 0.06 && Math.abs(b.angularVelocity) < 0.004) {
        M.Body.setVelocity(b, { x: b.velocity.x * 0.5, y: b.velocity.y * 0.5 });
        M.Body.setAngularVelocity(b, 0);
      }
      if (b.plugin.flash > 0) b.plugin.flash = Math.max(0, b.plugin.flash - 0.055);
      const settled = speed < 0.6;
      const age = now - b.plugin.spawnAt;
      if (age > 500 && settled && b.position.y - b.circleRadius < LINE_Y) b.plugin.overMs += 16.7;
      else b.plugin.overMs = 0;
      if (b.plugin.overMs > OVER_LIMIT) { gameOver(); return; }
    }
  }

  function mergeBodies(a, b) {
    const M = window.Matter;
    const newIndex = a.plugin.index + 1;
    const r = FRUITS[newIndex].size / 2;
    let x = (a.position.x + b.position.x) / 2;
    let y = (a.position.y + b.position.y) / 2;
    x = Math.max(r + 1, Math.min(PW - r - 1, x));
    y = Math.min(PH - r - 1, y);
    M.Composite.remove(engine.world, a);
    M.Composite.remove(engine.world, b);
    spawnFruit(newIndex, x, y, { flash: true, vx: (a.velocity.x + b.velocity.x) / 2, vy: -2.4 });
    state.score += MERGE_SCORE[newIndex];
    refs.scoreValue.textContent = String(state.score);
    Sfx.merge(newIndex);
    doVibrate(15);
    spawnScorePop(x, y, MERGE_SCORE[newIndex]);
  }

  function spawnScorePop(x, y, amount) {
    const pop = el('div'); pop.className = 'pop-score'; pop.textContent = '+' + amount;
    applyStyle(pop, { left: x, top: y });
    refs.board.appendChild(pop);
    setTimeout(() => pop.remove(), 750);
  }

  function syncBoardDom() {
    const nowMs = performance.now();
    const bodies = fruitBodies();
    const seen = new Set();
    for (const b of bodies) {
      seen.add(b.id);
      let ref = bodyEls.get(b.id);
      const f = FRUITS[b.plugin.index];
      const r = b.circleRadius;
      if (!ref) {
        const wrap = el('div'); wrap.className = 'board-fruit';
        wrap.appendChild(createFruitEl({ size: f.size, colorA: f.colorA, colorB: f.colorB, topper: f.topper }));
        const ring = el('div'); ring.className = 'ring'; ring.style.display = 'none';
        wrap.appendChild(ring);
        refs.board.appendChild(wrap);
        ref = { wrap, ring };
        bodyEls.set(b.id, ref);
      }
      const p = Math.min(1, (nowMs - b.plugin.spawnAt) / SPAWN_ANIM);
      const amp = 0.26 * (1 - p) * Math.cos(p * Math.PI * 2.2);
      const sx = 1 + amp, sy = 1 - amp;
      const rawDeg = (b.angle * 180) / Math.PI;
      const deg = Math.max(-18, Math.min(18, rawDeg % 360 > 180 ? (rawDeg % 360) - 360 : rawDeg % 360));
      applyStyle(ref.wrap, { left: b.position.x - r, top: b.position.y - r, width: f.size, height: f.size });
      ref.wrap.style.transform = `rotate(${deg.toFixed(2)}deg) scale(${sx.toFixed(3)},${sy.toFixed(3)})`;
      if (b.plugin.flash > 0.02) {
        ref.ring.style.display = 'block';
        ref.ring.style.opacity = String(b.plugin.flash);
        ref.ring.style.transform = `scale(${1 + (1 - b.plugin.flash) * 0.5})`;
      } else {
        ref.ring.style.display = 'none';
      }
    }
    for (const [id, ref] of bodyEls) {
      if (!seen.has(id)) { ref.wrap.remove(); bodyEls.delete(id); }
    }
  }

  function tick(now) {
    if (engine && state.screen === 'game') {
      const M = window.Matter;
      M.Engine.update(engine, 1000 / 120);
      M.Engine.update(engine, 1000 / 120);
      postStep(now || performance.now());
      syncBoardDom();
    }
    raf = requestAnimationFrame(tick);
  }

  function resetBoard() {
    lastDrop = 0;
    if (engine) {
      const M = window.Matter;
      fruitBodies().forEach((b) => M.Composite.remove(engine.world, b));
    }
    bodyEls.forEach((ref) => ref.wrap.remove());
    bodyEls.clear();
  }

  function gameOver() {
    state.highScore = Math.max(state.highScore, state.score);
    const earned = Math.floor(state.score / 10);
    state.coins += earned;
    persist();
    Sfx.gameOver();
    doVibrate(60);
    stopMusic();
    refs.goScoreValue.textContent = String(state.score);
    refs.goBestValue.textContent = String(state.highScore);
    refs.goCoinsLine.textContent = earned > 0 ? `+${earned} coins earned` : '';
    state.screen = 'gameover';
    renderScreenVisibility();
  }

  // ---------------- Drop control ----------------
  function handleBoardMove(e) {
    const rect = refs.boardWrap.getBoundingClientRect();
    let pct = ((e.clientX - rect.left) / rect.width) * 100;
    pct = Math.max(8, Math.min(92, pct));
    state.dropX = pct;
    updateDropPreview();
  }

  function dropFruit() {
    if (state.screen !== 'game') return;
    const now = Date.now();
    if (now - lastDrop < DROP_COOLDOWN) return;
    lastDrop = now;

    const idx = state.currentIndex;
    const r = FRUITS[idx].size / 2;
    let x = (state.dropX / 100) * BOARD_WIDTH - WALL;
    x = Math.max(r + 1, Math.min(PW - r - 1, x));
    spawnFruit(idx, x, r + 2, { vx: 0, vy: 2 });
    Sfx.drop();
    state.currentIndex = state.nextIndex;
    state.nextIndex = randomDropIndex();
    renderCurrentFruitPreview();
    updateNextPreview();
  }

  function updateDropPreview() {
    const pct = state.dropX + '%';
    refs.dropGuide.style.left = pct;
    refs.dropShadow.style.left = pct;
    refs.dropPreview.style.left = pct;
  }

  function renderCurrentFruitPreview() {
    refs.dropPreview.innerHTML = '';
    const f = FRUITS[state.currentIndex];
    refs.dropPreview.appendChild(createFruitEl({ size: f.size, colorA: f.colorA, colorB: f.colorB, topper: f.topper }));
  }

  function updateNextPreview() {
    refs.nextFruitSlot.innerHTML = '';
    const f = FRUITS[state.nextIndex];
    refs.nextFruitSlot.appendChild(createFruitEl({ size: 34, colorA: f.colorA, colorB: f.colorB, topper: f.topper }));
  }

  function startGame() {
    resetBoard();
    state.score = 0;
    state.currentIndex = randomDropIndex();
    state.nextIndex = randomDropIndex();
    state.dropX = 50;
    refs.scoreValue.textContent = '0';
    renderCurrentFruitPreview();
    updateNextPreview();
    updateDropPreview();
    state.screen = 'game';
    renderScreenVisibility();
    if (state.music) startMusic();
  }
  function restartGame() { startGame(); }

  // ---------------- Boot ----------------
  buildMenuScreen();
  buildGameScreen();
  buildPauseOverlay();
  buildGameOverScreen();
  buildShopScreen();
  buildSettingsScreen();

  renderCurrentFruitPreview();
  updateNextPreview();
  updateDropPreview();
  renderScreenVisibility();

  function boot() {
    if (!window.Matter) { setTimeout(boot, 60); return; }
    initPhysics();
    raf = requestAnimationFrame(tick);
  }
  boot();

  document.addEventListener('visibilitychange', () => {
    if (document.hidden && state.screen === 'game') pauseGame();
  });
})();
