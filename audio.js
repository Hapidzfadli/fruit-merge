(function () {
  let ctx = null;
  let musicNodes = null;

  function getCtx() {
    if (!ctx) ctx = new (window.AudioContext || window.webkitAudioContext)();
    if (ctx.state === 'suspended') ctx.resume();
    return ctx;
  }

  function tone(freq, { duration = 0.12, type = 'sine', gain = 0.18, glideTo = null, delay = 0 } = {}) {
    const c = getCtx();
    const osc = c.createOscillator();
    const g = c.createGain();
    osc.type = type;
    const t0 = c.currentTime + delay;
    osc.frequency.setValueAtTime(freq, t0);
    if (glideTo) osc.frequency.exponentialRampToValueAtTime(glideTo, t0 + duration);
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(gain, t0 + 0.01);
    g.gain.exponentialRampToValueAtTime(0.001, t0 + duration);
    osc.connect(g).connect(c.destination);
    osc.start(t0);
    osc.stop(t0 + duration + 0.02);
  }

  const SFX = {
    drop() { tone(320, { duration: 0.08, type: 'triangle', gain: 0.12, glideTo: 220 }); },
    merge(index) {
      const base = 260 + Math.min(index, 9) * 28;
      tone(base, { duration: 0.16, type: 'sine', gain: 0.2, glideTo: base * 1.9 });
      tone(base * 1.5, { duration: 0.1, type: 'sine', gain: 0.1, delay: 0.03, glideTo: base * 2.2 });
    },
    gameOver() {
      [440, 370, 300, 220].forEach((f, i) => tone(f, { duration: 0.22, type: 'sawtooth', gain: 0.12, delay: i * 0.13 }));
    },
    click() { tone(500, { duration: 0.05, type: 'square', gain: 0.06 }); },
    buy() {
      tone(520, { duration: 0.1, type: 'sine', gain: 0.15 });
      tone(780, { duration: 0.14, type: 'sine', gain: 0.12, delay: 0.08 });
    }
  };

  function startMusic() {
    if (musicNodes) return;
    const c = getCtx();
    const master = c.createGain();
    master.gain.value = 0.05;
    master.connect(c.destination);
    const notes = [261.6, 329.6, 392.0, 329.6];
    let i = 0;
    const oscs = [];
    const playNext = () => {
      const osc = c.createOscillator();
      const g = c.createGain();
      osc.type = 'sine';
      osc.frequency.value = notes[i % notes.length];
      g.gain.setValueAtTime(0, c.currentTime);
      g.gain.linearRampToValueAtTime(1, c.currentTime + 0.4);
      g.gain.linearRampToValueAtTime(0, c.currentTime + 1.6);
      osc.connect(g).connect(master);
      osc.start();
      osc.stop(c.currentTime + 1.7);
      i++;
    };
    playNext();
    const timer = setInterval(playNext, 1700);
    musicNodes = { master, timer };
  }

  function stopMusic() {
    if (!musicNodes) return;
    clearInterval(musicNodes.timer);
    musicNodes.master.disconnect();
    musicNodes = null;
  }

  function vibrate(ms) {
    if (navigator.vibrate) navigator.vibrate(ms);
  }

  window.GameAudio = { SFX, startMusic, stopMusic, vibrate, getCtx };
})();
