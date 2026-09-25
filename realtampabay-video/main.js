'use strict';
// Real Tampa Bay — 30 s, 9:16, hand-drawn + 8-bit look (after @nahiddotai) with a route-map story.
// Copy and numbers (sources in the delivery notes)
const TAGLINE = ['Real growth. Real development.', 'Real Tampa Bay.'];
const TIKTOK = '12.8K', INSTA = '12K', SUBS = 735, JOINED = 776;
const STAY = Math.round(SUBS / JOINED * 100); // 95
const REFERRAL = 100;

Object.assign(HD, { serif: 'GAMETITLE', accent: '#f2e63c', dark: '#070707', tag: '#e7dfcc', ink: '#262523' });
const Y = HD.accent, INK = HD.ink;

// ---------- cast ----------
Object.assign(MINIS, {
  rtb: { name: 'RTB', color: Y, body: Y, pal: { k: INK, Y, E: INK, w: '#ffffff' }, rows: [
    '....k..k..k.....',
    '.kk..k.k.k..kk..',
    '...kk.kkk.kk....',
    '......kkk.......',
    '..kkkkkkkkkkkk..',
    '..kYYYYYYYYYYk..',
    '..kYYYYYYYYYYk..',
    '..kYYEEYYEEYYk..',
    '..kYYEEYYEEYYk..',
    '..kYYYYYYYYYYk..',
    '..kYYkYYYYkYYk..',
    '..kYYYkkkkYYYk..',
    '..kkkkkkkkkkkk..',
    '...kk......kk...'] },
  pelican: { name: 'PELICAN', color: '#ffffff', body: '#ffffff', pal: { k: INK, W: '#ffffff', Y, E: INK }, rows: [
    '....kkk.........',
    '...kWWWk........',
    '...kWEWkkkkkk...',
    '...kWWWYYYYYYk..',
    '...kWWkkYYYYk...',
    '..kWWWk.kkkk....',
    '.kWWWWWk........',
    'kWWWWWWWk.......',
    'kWWWWWWWWk......',
    '.kWWWWWWWk......',
    '..kkkkkkk.......',
    '....k..k........',
    '...kk.kk........'] },
  crane: { name: 'CRANE', color: Y, body: Y, pal: { k: INK, Y }, rows: [
    'kkkkkkkkkkkkkkkk',
    'kYkYkYkYkYkYkYYk',
    'kkkkkYkkkkkkkkkk',
    '....kYk.......k.',
    '....kYk.......k.',
    '....kYk......kkk',
    '....kYk......kYk',
    '....kYk......kkk',
    '....kYk.........',
    '....kYk.........',
    '....kYk.........',
    '...kkkkk........',
    '..kkkkkkk.......'] },
  drone: { name: 'DRONE', color: INK, body: Y, pal: { k: INK, Y, E: INK, C: '#e0463a' }, rows: [
    'kkkk......kkkk',
    '..k...C....k..',
    '..kkkkkkkkkk..',
    '...kYYYYYYk...',
    '...kYEYYEYk...',
    '...kkkkkkkk...',
    '....k....k....'] },
  streetcar: { name: 'STREETCAR', color: Y, body: Y, pal: { k: INK, Y, W: '#ffffff', E: INK }, rows: [
    '.......kk.......',
    '....kkkkkkkk....',
    '.kkkkkkkkkkkkkk.',
    '.kYYYYYYYYYYYYk.',
    '.kYWWkWWkWWkYYk.',
    '.kYWWkWWkWWkYYk.',
    '.kYYYYYYYYYYYYk.',
    '.kkkkkkkkkkkkkk.',
    '...kk......kk...'] },
});

// ---------- helpers ----------
const fadeIn = t => flash(1 - prog(t, 0, .12), '#fff');
function tag(s) { text(s, 56, 70, { font: HD.mono, size: 26, color: HD.muted, align: 'left', jit: false }); }
function heading(s, sub, t, y = 210) {
  text(s, W / 2, y, { font: HD.serif, weight: 600, size: 84, color: INK, reveal: E.out(prog(t, 0, .45)), jit: false });
  if (sub) text(sub, W / 2, y + 82, { font: HD.script, size: 42, color: INK, alpha: prog(t, .3, .7), jit: false, maxW: W - 120 });
}
function nameTag(s, x, y, a = 1) { text(s, x, y, { font: HD.mono, size: 20, color: HD.muted, alpha: a, jit: false }); }
function hl(x, y, w, h, p, id) { ctx.save(); ctx.globalCompositeOperation = 'multiply'; highlight(x, y, w, h, p, id, Y); ctx.restore(); }

// ---------- route map ----------
const MEDIA = [[200, 380], [200, 900], [540, 1100], [880, 1300], [880, 1730]];
const STORY = [[140, 1730], [140, 1400], [540, 1100], [940, 800], [940, 380]];
const HUB = [540, 1100];
const M_ST = [[200, 500, 'HDR Photos', 'next-day delivery', 'R'], [200, 780, 'Video', '', 'R'],
  [880, 1380, 'Drone', 'FAA-certified', 'L'], [880, 1520, '3D Tours', '', 'L'], [880, 1660, 'Virtual Staging', '', 'L']];
const S_ST = [[140, 1640, 'Newsletter', 'weekly brief', 'R'], [140, 1460, 'TikTok', '', 'R'],
  [940, 720, 'Instagram', '', 'L'], [940, 520, 'YouTube', '', 'L']];
// fraction along a polyline where it passes closest to (x, y)
function fracAt(pts, x, y) {
  const L = [0]; for (let i = 1; i < pts.length; i++) L.push(L[i - 1] + Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]));
  let best = 1e9, at = 0;
  for (let i = 1; i < pts.length; i++) for (let k = 0; k <= 50; k++) {
    const f = k / 50, px = lerp(pts[i - 1][0], pts[i][0], f), py = lerp(pts[i - 1][1], pts[i][1], f), d = Math.hypot(px - x, py - y);
    if (d < best) { best = d; at = (L[i - 1] + f * (L[i] - L[i - 1])) / L[L.length - 1]; }
  }
  return at;
}
const headAt = (pts, p) => { const q = polyPart(pts, clamp(p)); return q[q.length - 1]; };
function routeLine(pts, p, id, fill) {
  sketch(pts, p, id, { stroke: INK, strokeWidth: fill ? 20 : 12, roughness: .7, bowing: .4 }, 6);
  if (fill) sketch(pts, p, id + 1, { stroke: fill, strokeWidth: 10, roughness: .5, bowing: .3 }, 6);
}
function station([x, y, label, sub, side], a, id, dim = 1) {
  if (a <= 0) return;
  const k = E.back(clamp(a * 1.6));
  rc.circle(x, y, 34 * k, ro(id, { stroke: INK, strokeWidth: 4, fill: '#ffffff', fillStyle: 'solid', roughness: .6 }));
  const al = clamp(a * 2) * dim, tx = side === 'R' ? x + 44 : x - 44, align = side === 'R' ? 'left' : 'right';
  text(label, tx, y - 4, { font: HD.sans, weight: 800, size: 42, color: INK, align, alpha: al, jit: false });
  if (sub) text(sub, tx, y + 38, { font: HD.script, size: 34, color: INK, align, alpha: al * prog(a, .3, 1), jit: false });
}
function hub(a, id, pulse = 0) {
  if (a <= 0) return;
  const [x, y] = HUB, k = E.back(clamp(a * 1.6));
  rc.circle(x, y, 70 * k, ro(id, { stroke: INK, strokeWidth: 5, fill: '#ffffff', fillStyle: 'solid', roughness: .6 }));
  rc.circle(x, y, 34 * k, ro(id + 1, { stroke: INK, strokeWidth: 4, fill: Y, fillStyle: 'solid', roughness: .6 }));
  if (pulse > 0 && pulse < 1) rc.circle(x, y, 70 + pulse * 160, ro(id + 2, { stroke: INK, strokeWidth: 3 * (1 - pulse), roughness: .8 }));
  text('TAMPA BAY', 606, 1086, { font: HD.pix, size: 26, color: INK, align: 'left', alpha: clamp(a * 2), jit: false });
  text('interchange', 614, 1128, { font: HD.script, size: 34, color: INK, align: 'left', alpha: clamp(a * 2), jit: false });
}
function mediaMap(p, dim = 1) {
  routeLine(MEDIA, p, 3000, Y);
  M_ST.forEach((s, i) => station(s, (p - fracAt(MEDIA, s[0], s[1])) * 8, 3010 + i, dim));
  hub((p - fracAt(MEDIA, ...HUB)) * 8, 3050);
}

// ---------- scenes ----------
// 0–2.6 asleep on the horizon, a drone buzzes in, power-up
function sWake(t) {
  hdPaper();
  cloud(250 + t * 10, 420, 1.1, 101); cloud(860 - t * 8, 330, .8, 102);
  const gy = 1260; horizon(gy, 110);
  const up = prog(t, 1.4, 2.1), jump = Math.sin(up * Math.PI) * 150;
  burst(540, gy - 100, 280, prog(t, 1.4, 1.9), Y, 130);
  drawMini('rtb', 540, gy - jump, 12, { blink: t < 1.4 });
  if (t < 1.4) zzz(640, gy - 190, t);
  const dx = lerp(1250, 800, E.out(prog(t, .5, 1.3))), dy = 900 + Math.sin(t * 9) * 12;
  drawMini('drone', dx, dy, 7);
  zoomLines(prog(t, 2.3, 2.6), INK, W / 2, gy - 100);
}
// 2.6–5.8 dark title card
function sIntro(t) {
  hdDark();
  fadeIn(t);
  const size = 170, x0 = 110;
  text('Introducing', W / 2, 700, { font: HD.serif, size: 54, color: '#cfcac1', alpha: prog(t, 0, .3), jit: false });
  const l1 = 'Real', l2 = 'Tampa Bay', shown = typed(l1 + l2, prog(t, .2, .2 + 13 * .055));
  text(shown.slice(0, 4), W / 2, 860, { font: HD.serif, weight: 500, size, color: HD.light, jit: false });
  const w2 = measure(l2, HD.serif, size, 500);
  text(shown.slice(4), W / 2 - w2 / 2, 1050, { font: HD.serif, weight: 500, size, color: Y, align: 'left', jit: false });
  const u = prog(t, .95, 1.3);
  sketch([[W / 2 - w2 / 2, 1140], [W / 2, 1148], [W / 2 + w2 / 2, 1134]], u, 210, { stroke: Y, strokeWidth: 7, roughness: .9 });
  if (u > 0) drawMini('rtb', W / 2 + w2 / 2 - 40, 972 - Math.sin(prog(t, 1.3, 1.6) * Math.PI) * 40, 4.5, { alpha: prog(t, 1.2, 1.35) });
  TAGLINE.forEach((s, i) => text(s, W / 2, 1270 + i * 70, { font: HD.script, size: 56, color: '#f6ef9a', alpha: prog(t, 1.3, 1.6), jit: false }));
  void x0;
}
// 5.8–12.2 WORLD 1-1: the media line draws, the mascot rides it
function sMedia(t) {
  hdPaper(); fadeIn(t);
  tag('WORLD 1-1');
  heading('The Media Line', '', t);
  const p = E.inOut(prog(t, .3, 4.0));
  mediaMap(p);
  const da = clamp((p - fracAt(MEDIA, 880, 1380)) * 8), dr = [965, 1330 + Math.sin(t * 8) * 10];
  if (da > 0) { drawMini('drone', dr[0], dr[1], 5, { alpha: da }); }
  const [hx, hy] = headAt(MEDIA, p);
  drawMini('rtb', hx, hy - 12 - Math.abs(Math.sin(t * 10)) * 10, 5);
}
// 12.2–15.6 WORLD 1-2: no sq-ft fees, $100 referral credit
function sPrice(t) {
  hdPaper(); fadeIn(t);
  tag('WORLD 1-2');
  text('bundle pricing', W / 2, 250, { font: HD.serif, weight: 600, size: 80, color: INK, reveal: E.out(prog(t, 0, .4)), jit: false });
  const acc = HD.accent; HD.accent = '#c8372d'; priceTag(560, 600, 'sq-ft', '$0', prog(t, .3, 1.3), 310); HD.accent = acc;
  const p = prog(t, 1.1, 1.7);
  if (p > 0) {
    hl(W / 2 - 270, 935, 540, 150, prog(t, 1.3, 1.6), 320);
    text(countUp(REFERRAL, p, { prefix: '$' }), W / 2, 1010, { font: HD.pix, size: 120, color: INK, jit: false });
    text('referral credit — each', W / 2, 1140, { font: HD.sans, weight: 700, size: 42, color: INK, alpha: prog(p, .4, .8), jit: false });
    text('refer an agent, you both get it', W / 2, 1210, { font: HD.script, size: 46, color: INK, alpha: prog(p, .4, .8), jit: false });
  }
  horizon(1560, 330);
  drawMini('rtb', 540, 1560 - Math.abs(Math.sin(prog(t, 1.8, 2.4) * Math.PI)) * 60, 8);
}
// 15.6–17.2 torn paper into the full-bleed yellow WORLD 2 card
function sWorld2(t) {
  const tp = prog(t, 0, .45);
  if (tp < 1) { sPrice(3.3); paperTear(tp, Y); return; }
  t -= .45;
  ctx.save(); ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.fillStyle = Y; ctx.fillRect(0, 0, W, H); ctx.restore();
  const k = E.back(prog(t, 0, .3));
  if (k <= 0) return;
  ctx.save(); ctx.translate(W / 2, H / 2); ctx.scale(k, k);
  rc.rectangle(-440, -170, 880, 340, ro(410, { stroke: INK, strokeWidth: 6, roughness: .6 }));
  text('WORLD 2', 0, -62, { font: HD.pix, size: 34, color: INK, jit: false });
  text('STORY LINE', 0, 40, { font: HD.pix, size: 62, color: INK, jit: false });
  ctx.restore();
  drawMini('rtb', W / 2, H / 2 + 460 - Math.abs(Math.sin(t * 6)) * 30, 8);
}
// 17.2–22 WORLD 2-1: the story line crosses the media line at Tampa Bay
function sStory(t) {
  hdPaper(); fadeIn(t);
  tag('WORLD 2-1');
  heading('The Story Line', '', t);
  routeLine(MEDIA, 1, 3000, Y);
  M_ST.forEach((s, i) => station(s, 1, 3010 + i, .35));
  const p = E.inOut(prog(t, .3, 3.0)), fh = fracAt(STORY, ...HUB);
  routeLine(STORY, p, 3100, null);
  S_ST.forEach((s, i) => station(s, (p - fracAt(STORY, s[0], s[1])) * 8, 3110 + i));
  hub(1, 3050, (p - fh) * 3);
  const pa = prog(p, fh - .02, fh + .06), pj = Math.sin(prog(p, fh, fh + .12) * Math.PI) * 50;
  drawMini('pelican', 610, 1290 - pj, 5, { alpha: .4 + .6 * pa }); 
  const [hx, hy] = headAt(STORY, p);
  drawMini('streetcar', hx, hy - 10, 5);
}
// 22–24.8 HI-SCORE board
function sScore(t) {
  hdDark();
  rc.rectangle(60, 260, W - 120, H - 520, ro(510, { stroke: '#d8d3ca', strokeWidth: 2.6, roughness: .7 }));
  text('HI-SCORE', W / 2, 520, { font: HD.pix, size: 76, color: Y, jit: false });
  text('followers & readers · Sept 2026', W / 2, 610, { font: HD.sans, size: 32, color: '#bdb8ae', jit: false });
  const rows = [['1ST', 'TIKTOK', TIKTOK], ['2ND', 'INSTAGRAM', INSTA], ['3RD', 'NEWSLETTER', String(SUBS)]];
  rows.forEach(([r, n, s], i) => {
    const a = prog(t, .25 + i * .3, .45 + i * .3);
    if (a <= 0) return;
    const y = 820 + i * 160, c = i === 0 ? Y : HD.light;
    text(r, 150, y, { font: HD.pix, size: 40, color: c, align: 'left', alpha: a, jit: false });
    text(n, 320, y, { font: HD.pix, size: 38, color: c, align: 'left', alpha: a, jit: false });
    text(s, 990, y, { font: HD.pix, size: 40, color: c, align: 'right', alpha: a, jit: false });
    if (i === 0) drawMini('rtb', 102, y + 22, 3, { alpha: a });
  });
  if (t > 1.3 && Math.floor(T * 4) % 2) text('IG JUST HIT 12K!', W / 2, 1360, { font: HD.pix, size: 34, color: HD.light, jit: false });
}
// 24.8–27.2 WORLD 2-2: readers stay (hatched vs solid)
function sBars(t) {
  hdPaper(); fadeIn(t);
  tag('WORLD 2-2');
  text('Readers stay.', W / 2, 230, { font: HD.serif, weight: 600, size: 96, color: INK, reveal: E.out(prog(t, 0, .4)), jit: false });
  const p = prog(t, .1, .8);
  const tops = hatchBars([{ label: 'joined', v: JOINED, text: String(JOINED) }, { label: 'still reading', v: SUBS, hi: true }],
    { x: 250, y: 1250, w: 580, h: 760, p, id: 610 });
  if (p > .9) text(String(SUBS), tops[1][0], tops[1][1] - 150, { font: HD.pix, size: 48, color: INK, jit: false });
  drawMini('rtb', tops[1][0], tops[1][1], 5);
  const q = prog(t, .7, 1.2);
  if (q > 0) {
    hl(W / 2 - 170, 1400, 340, 130, prog(t, .9, 1.2), 620);
    text(countUp(STAY, q, { suffix: '%' }), W / 2, 1475, { font: HD.pix, size: 104, color: INK, jit: false });
    text('stay subscribed', W / 2, 1590, { font: HD.sans, weight: 700, size: 40, color: INK, alpha: prog(q, .3, .6), jit: false });
  }
}
// 27.2–30 ending
function sEnd(t) {
  hdPaper();
  circleWipe(1 - prog(t, 0, .35), Y, W / 2, H / 2);
  const k = E.back(prog(t, .1, .45)), s = 400 * k;
  if (k > 0 && IMG.logo) {
    ctx.save(); rr(W / 2 - s / 2, 520 - s / 2, s, s, 36 * k); ctx.clip(); ctx.drawImage(IMG.logo, W / 2 - s / 2, 520 - s / 2, s, s); ctx.restore();
  }
  text('Real Tampa Bay', W / 2, 860, { font: HD.serif, weight: 600, size: 104, color: INK, alpha: prog(t, .3, .5), jit: false });
  const w = measure('Real Tampa Bay', HD.serif, 104, 600);
  sketch([[W / 2 - w / 2, 925], [W / 2, 932], [W / 2 + w / 2, 920]], prog(t, .5, .8), 810, { stroke: Y, strokeWidth: 10, roughness: .9 });
  sketch([[W / 2 - w / 2, 925], [W / 2, 932], [W / 2 + w / 2, 920]], prog(t, .5, .8), 811, { stroke: INK, strokeWidth: 2, roughness: .9 });
  text('Get the weekly brief', W / 2, 1020, { font: HD.sans, weight: 700, size: 44, color: INK, alpha: prog(t, .5, .7), jit: false });
  text('realtampabay.com     @realtampabay', W / 2, 1100, { font: HD.mono, size: 34, color: INK, alpha: prog(t, .6, .8), jit: false });
  const gy = 1560; horizon(gy, 820);
  const cast = [['crane', 170, 6], ['pelican', 360, 5], ['rtb', 560, 8], ['streetcar', 820, 5]];
  cast.forEach(([m, x, sc], i) => {
    const a = prog(t, .7 + i * .1, .9 + i * .1), hop = Math.sin(prog(t, .7 + i * .1, 1.1 + i * .1) * Math.PI) * 50;
    drawMini(m, x, gy - hop, sc, { alpha: a });
  });
  drawMini('drone', 700 + Math.sin(t * 2) * 30, 1320 + Math.sin(t * 8) * 10, 5, { alpha: prog(t, 1.3, 1.5) });
}

boot({
  scenes: [[0, 2.6, sWake], [2.6, 5.8, sIntro], [5.8, 12.2, sMedia], [12.2, 15.6, sPrice], [15.6, 17.2, sWorld2],
    [17.2, 22, sStory], [22, 24.8, sScore], [24.8, 27.2, sBars], [27.2, 30, sEnd]],
  images: { logo: 'assets/logo.jpg' },
  fonts: [['GAMETITLE', 'Aa'], ['SCRIPT', 'Aa'], ['PIX', 'A'], ['MONO', 'A'], ['SANS', 'A']],
  noise: 6,
});
