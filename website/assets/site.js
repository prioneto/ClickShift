(() => {
  const demo = document.querySelector('#demo');
  const panel = document.querySelector('#clickshiftPanel');
  const menuToggle = document.querySelector('#menuToggle');
  const connectionTitle = document.querySelector('#connectionTitle');
  const connectionDetail = document.querySelector('#connectionDetail');
  const gearNumber = document.querySelector('#gearNumber');
  const gearReadout = document.querySelector('.gear-readout');

  const stateCopy = {
    idle: ['Waiting for your ride app', 'Opens when your selected app starts'],
    connected: ['Click v2 connected', 'Your ride app is open · Ready to shift'],
    safe: ['App-only safety is on', 'Shortcuts stay inside your selected training app'],
    searching: ['Searching for right Click v2…', 'Press + or B once to wake the controller'],
    mapping: ['Custom controls ready', '+ sends K · B sends I'],
    step: ['Three-step shift selected', 'One press can move 1, 2, or 3 virtual gears'],
    profile: ['MyWhoosh selected', 'ROUVY, TrainingPeaks Virtual, or any custom app'],
    private: ['Everything stays local', 'No account, analytics, ride data, or network service'],
    native: ['Native macOS app', 'Universal for Apple Silicon and Intel']
  };

  function setState(state) {
    if (!demo) return;
    demo.dataset.state = state;
    const copy = stateCopy[state] || stateCopy.idle;
    if (connectionTitle) connectionTitle.textContent = copy[0];
    if (connectionDetail) connectionDetail.textContent = copy[1];
    if (panel?.classList.contains('is-hidden')) {
      panel.classList.remove('is-hidden');
      menuToggle?.setAttribute('aria-expanded', 'true');
    }
  }

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
