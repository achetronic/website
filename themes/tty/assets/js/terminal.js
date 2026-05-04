// achetronic blog — micro-interactions
(function () {
  'use strict';

  // reading progress bar — only on post single (where .reading-progress div exists)
  function setupReadingProgress() {
    var bar = document.querySelector('.reading-progress');
    if (!bar) return;
    function update() {
      var doc = document.documentElement;
      var max = (doc.scrollHeight - window.innerHeight);
      if (max <= 0) { bar.style.transform = 'scaleX(0)'; return; }
      var p = Math.min(1, Math.max(0, window.scrollY / max));
      bar.style.transform = 'scaleX(' + p + ')';
    }
    update();
    window.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', update, { passive: true });
  }

  // keyboard-navigation detection to enable focus rings
  function setupKeyboardFocus() {
    function on()  { document.documentElement.classList.add('using-keyboard'); }
    function off() { document.documentElement.classList.remove('using-keyboard'); }
    window.addEventListener('keydown', function (e) {
      if (e.key === 'Tab') on();
    });
    window.addEventListener('mousedown', off);
  }

  // copy button on code blocks
  function setupCodeCopy() {
    var blocks = document.querySelectorAll('.post-content .codeblock, .post-content .highlight');
    if (!blocks.length || !navigator.clipboard) return;
    blocks.forEach(function (block) {
      // if a .highlight is nested inside a .codeblock, skip it (the wrapper already gets the button)
      if (block.classList.contains('highlight') && block.closest('.codeblock')) return;
      var btn = document.createElement('button');
      btn.className = 'copy-btn';
      btn.type = 'button';
      btn.setAttribute('aria-label', 'Copiar al portapapeles');
      btn.textContent = 'copy';
      block.appendChild(btn);
      btn.addEventListener('click', function () {
        var code = block.querySelector('code');
        if (!code) return;
        navigator.clipboard.writeText(code.innerText).then(function () {
          btn.textContent = 'ok';
          btn.classList.add('copied');
          setTimeout(function () {
            btn.textContent = 'copy';
            btn.classList.remove('copied');
          }, 1400);
        }).catch(function () {
          btn.textContent = 'err';
          setTimeout(function () { btn.textContent = 'copy'; }, 1400);
        });
      });
    });
  }

  // theme toggle (dark / light) — persisted in localStorage
  function setupThemeToggle() {
    var btn = document.querySelector('.theme-toggle');
    if (!btn) return;
    function apply(t) {
      document.documentElement.setAttribute('data-theme', t);
      btn.setAttribute('aria-label', t === 'dark' ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro');
    }
    apply(document.documentElement.getAttribute('data-theme') || 'light');
    btn.addEventListener('click', function () {
      var current = document.documentElement.getAttribute('data-theme');
      var next = current === 'dark' ? 'light' : 'dark';
      try { localStorage.setItem('theme', next); } catch (e) {}
      apply(next);
    });
  }

  // lightbox for images inside post content
  function setupLightbox() {
    var imgs = document.querySelectorAll('.post-content img');
    if (!imgs.length) return;

    var overlay = document.createElement('div');
    overlay.className = 'lightbox';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');
    overlay.setAttribute('aria-label', 'Vista ampliada');
    overlay.innerHTML =
      '<button type="button" class="lightbox-close" aria-label="Cerrar">×</button>' +
      '<div class="lightbox-stage"><img class="lightbox-img" alt=""></div>';
    document.body.appendChild(overlay);

    var stageImg = overlay.querySelector('.lightbox-img');
    var btn = overlay.querySelector('.lightbox-close');

    function open(src, alt) {
      stageImg.src = src;
      stageImg.alt = alt || '';
      overlay.classList.add('open');
      document.documentElement.classList.add('lightbox-active');
    }
    function close() {
      overlay.classList.remove('open');
      document.documentElement.classList.remove('lightbox-active');
      // small delay to clear src so the closing animation doesn't flicker
      setTimeout(function () { stageImg.src = ''; }, 220);
    }

    imgs.forEach(function (img) {
      img.classList.add('zoomable');
      img.addEventListener('click', function () { open(img.currentSrc || img.src, img.alt); });
    });

    // any click closes the lightbox except clicks on the image itself
    overlay.addEventListener('click', function (e) {
      if (e.target !== stageImg) close();
    });
    stageImg.addEventListener('click', function () { close(); });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && overlay.classList.contains('open')) close();
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    setupReadingProgress();
    setupKeyboardFocus();
    setupCodeCopy();
    setupThemeToggle();
    setupLightbox();
  });
})();

