(function () {
  const UNITLESS = new Set(['opacity', 'zIndex', 'flexShrink', 'flexGrow', 'fontWeight', 'lineHeight', 'order']);

  function applyStyle(el, style) {
    for (const k in style) {
      const v = style[k];
      if (v === undefined || v === null) continue;
      el.style[k] = typeof v === 'number' && !UNITLESS.has(k) ? v + 'px' : v;
    }
  }

  function el(tag, style) {
    const node = document.createElement(tag);
    if (style) applyStyle(node, style);
    return node;
  }

  function createFruitEl({ size = 80, colorA = '#FFB199', colorB = '#FF7043', topper = 'none', eyes = 'normal' } = {}) {
    const eye = size * 0.10;
    const eyeGap = size * 0.20;
    const eyeTop = size * 0.36;
    const blushSize = size * 0.17;
    const blushTop = size * 0.56;
    const blushGap = size * 0.31;
    const mouthW = size * 0.16;
    const mouthH = size * 0.10;
    const shineW = size * 0.32;
    const shineH = size * 0.20;
    const eyeShineSize = Math.max(2, eye * 0.4);
    const xSize = size * 0.15;
    const barT = Math.max(2, size * 0.032);
    const isX = eyes === 'x';

    const wrap = el('div', {
      width: size, height: size, borderRadius: '50%',
      background: `radial-gradient(circle at 35% 28%, ${colorA}, ${colorB})`,
      boxShadow: `inset -${size * 0.08}px -${size * 0.10}px ${size * 0.18}px rgba(0,0,0,0.18), inset ${size * 0.05}px ${size * 0.05}px ${size * 0.12}px rgba(255,255,255,0.55), 0 ${size * 0.06}px ${size * 0.12}px rgba(0,0,0,0.15)`,
      position: 'relative', flexShrink: 0
    });
    wrap.className = 'fruit-face';

    if (topper === 'leaf') {
      wrap.appendChild(el('div', {
        position: 'absolute', top: -size * 0.08, left: '50%', width: size * 0.28, height: size * 0.16,
        transform: 'translateX(-50%)', background: '#6FBF5A', borderRadius: '50% 50% 20% 20%'
      }));
    } else if (topper === 'crown') {
      wrap.appendChild(el('div', {
        position: 'absolute', top: -size * 0.22, left: '50%', width: size * 0.5, height: size * 0.32,
        transform: 'translateX(-50%)', background: '#6FBF5A',
        clipPath: 'polygon(0% 100%,15% 0%,30% 60%,50% 0%,70% 60%,85% 0%,100% 100%)'
      }));
    }

    wrap.appendChild(el('div', {
      position: 'absolute', top: size * 0.14, left: size * 0.16, width: shineW, height: shineH,
      borderRadius: '50%', background: 'rgba(255,255,255,0.65)', transform: 'rotate(-25deg)'
    }));

    if (!isX) {
      [-1, 1].forEach((side) => {
        const eyeEl = el('div', {
          position: 'absolute', top: eyeTop, left: size / 2 + side * eyeGap - eye / 2,
          width: eye, height: eye * 1.15, borderRadius: '50%', background: '#4A3428'
        });
        eyeEl.appendChild(el('div', {
          position: 'absolute', top: '10%', left: '15%', width: eyeShineSize, height: eyeShineSize,
          borderRadius: '50%', background: '#fff'
        }));
        wrap.appendChild(eyeEl);
      });
    } else {
      [-1, 1].forEach((side) => {
        const xWrap = el('div', {
          position: 'absolute', top: eyeTop - xSize * 0.2, left: size / 2 + side * eyeGap - xSize / 2,
          width: xSize, height: xSize
        });
        xWrap.appendChild(el('div', {
          position: 'absolute', top: '50%', left: 0, width: '100%', height: barT, borderRadius: barT,
          background: '#4A3428', transform: 'translateY(-50%) rotate(45deg)'
        }));
        xWrap.appendChild(el('div', {
          position: 'absolute', top: '50%', left: 0, width: '100%', height: barT, borderRadius: barT,
          background: '#4A3428', transform: 'translateY(-50%) rotate(-45deg)'
        }));
        wrap.appendChild(xWrap);
      });
    }

    [-1, 1].forEach((side) => {
      wrap.appendChild(el('div', {
        position: 'absolute', top: blushTop, left: size / 2 + side * blushGap - blushSize / 2,
        width: blushSize, height: blushSize * 0.62, borderRadius: '50%', background: 'rgba(255,90,120,0.35)'
      }));
    });

    wrap.appendChild(isX
      ? el('div', {
          position: 'absolute', top: size * 0.60, left: '50%', width: mouthW * 0.8, height: mouthH * 0.9,
          transform: 'translateX(-50%)', borderTop: `${barT}px solid #4A3428`, borderRadius: '50% 50% 0 0'
        })
      : el('div', {
          position: 'absolute', top: size * 0.60, left: '50%', width: mouthW, height: mouthH,
          transform: 'translateX(-50%)', borderBottom: `${Math.max(2, size * 0.035)}px solid #4A3428`, borderRadius: '0 0 50% 50%'
        }));

    return wrap;
  }

  window.FruitUI = { createFruitEl, applyStyle, el };
})();
