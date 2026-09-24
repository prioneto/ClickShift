(() => {
  const demo = document.querySelector('#demo');
  const panel = document.querySelector('#clickshiftPanel');
  const menuToggle = document.querySelector('#menuToggle');
  const panelBadge = document.querySelector('#panelBadge');
  const clickStatus = document.querySelector('#clickStatus');
  const appStatus = document.querySelector('#appStatus');
  const panelHint = document.querySelector('#panelHint');
  const clickGlyph = document.querySelector('#clickGlyph');
  const appGlyph = document.querySelector('#appGlyph');
  const gearNumber = document.querySelector('#gearNumber');
  const gearReadout = document.querySelector('.gear-readout');

  const connected = { tone: 'ready', badge: 'Connected', click: 'Connected', app: 'Open' };
  const states = {
    idle: { tone: 'idle', badge: 'Waiting', click: 'Waiting for MyWhoosh', app: 'Not running', hint: 'Connects automatically when your ride app opens.' },
    connected: { ...connected, hint: 'Ready to shift. Press + or B, or click a shift row.' },
    safe: { ...connected, hint: 'App-only safety is on: shortcuts go only to your training app.' },
    searching: { tone: 'working', badge: 'Searching', click: 'Searching…', app: 'Open', hint: 'Press a button on the right Click to wake it.' },
    mapping: { ...connected, hint: 'Choose any Click button and keyboard key in Settings.' },
    step: { ...connected, hint: 'One press can move 1, 2, or 3 virtual gears.' },
    profile: { ...connected, hint: 'MyWhoosh, ROUVY, TrainingPeaks Virtual, or any custom app.' },
    private: { ...connected, hint: 'Everything stays on your Mac. No account, analytics, or network.' },
    native: { ...connected, hint: 'Native Swift app, universal for Apple Silicon and Intel.' }
  };

  function setState(state) {
    if (!demo) return;
    const copy = states[state] || states.idle;
    demo.dataset.state = state;
    demo.dataset.tone = copy.tone;
    if (panelBadge) panelBadge.textContent = copy.badge;
    if (clickStatus) clickStatus.textContent = copy.click;
    if (appStatus) appStatus.textContent = copy.app;
    if (panelHint) panelHint.textContent = copy.hint;
    clickGlyph?.classList.toggle('is-on', copy.tone === 'ready');
    clickGlyph?.classList.toggle('is-working', copy.tone === 'working');
    appGlyph?.classList.toggle('is-on', copy.app === 'Open');
    if (panel?.classList.contains('is-hidden')) {
      panel.classList.remove('is-hidden');
      menuToggle?.setAttribute('aria-expanded', 'true');
    }
  }

  setState(demo?.dataset.state || 'idle');

  menuToggle?.addEventListener('click', () => {
    panel?.classList.toggle('is-hidden');
    menuToggle.setAttribute('aria-expanded', String(!panel?.classList.contains('is-hidden')));
  });

  document.querySelectorAll('.shift-control').forEach(button => {
    button.addEventListener('click', () => {
      if (!gearNumber || !gearReadout) return;
      const direction = button.dataset.shift === 'up' ? 1 : -1;
      const next = Math.max(1, Math.min(30, Number(gearNumber.textContent) + direction));
      gearNumber.textContent = String(next);
      gearReadout.classList.remove('bump');
      requestAnimationFrame(() => gearReadout.classList.add('bump'));
      setState('connected');
    });
  });

  document.querySelectorAll('.feature[data-demo-state]').forEach(feature => {
    feature.addEventListener('mouseenter', () => setState(feature.dataset.demoState));
    feature.addEventListener('focus', () => setState(feature.dataset.demoState));
    feature.addEventListener('click', () => {
      setState(feature.dataset.demoState);
      demo?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
  });

  document.querySelectorAll('.faq-question').forEach(question => {
    question.addEventListener('click', () => {
      const item = question.closest('.faq-item');
      const isOpen = item?.classList.toggle('open') || false;
      question.setAttribute('aria-expanded', String(isOpen));
    });
  });
})();
