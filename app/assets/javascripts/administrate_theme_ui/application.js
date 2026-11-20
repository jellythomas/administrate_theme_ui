// administrate_theme_ui — vanilla JS, no build step. Works with and without Turbo.
(function () {
  "use strict";
  if (window.AdministrateThemeUi) return;

  var KEY = "atu:prefs";
  var root = document.documentElement;
  var media = window.matchMedia("(prefers-color-scheme: dark)");

  function prefs() {
    try { return JSON.parse(localStorage.getItem(KEY) || "{}"); } catch (e) { return {}; }
  }
  function save(patch) {
    var next = Object.assign(prefs(), patch);
    try { localStorage.setItem(KEY, JSON.stringify(next)); } catch (e) { /* private mode: prefs live for this page only */ }
    return next;
  }

  // ---------- Theme + mode ----------
  function currentMode() { return prefs().mode || root.dataset.modeDefault || "system"; }
  function applyPrefs() {
    var p = prefs();
    if (p.theme && root.dataset.themeSwitch === "true") root.dataset.theme = p.theme;
    var mode = currentMode();
    root.dataset.mode = mode === "system" ? (media.matches ? "dark" : "light") : mode;
    syncSwitcher();
    renderCharts();
  }
  function syncSwitcher() {
    var select = document.querySelector("[data-atu-theme-select]");
    if (select) select.value = root.dataset.theme;
    var mode = currentMode();
    document.querySelectorAll("[data-atu-mode]").forEach(function (b) {
      b.setAttribute("aria-checked", String(b.dataset.atuMode === mode));
    });
  }
  media.addEventListener("change", function () { if (currentMode() === "system") applyPrefs(); });

  document.addEventListener("change", function (e) {
    if (e.target.matches("[data-atu-theme-select]")) { save({ theme: e.target.value }); applyPrefs(); }
  });

  // ---------- Modals ----------
  function openModal(id) {
    var d = typeof id === "string" ? document.getElementById(id) : id;
    if (d && typeof d.showModal === "function" && !d.open) { d.classList.remove("is-closing"); d.showModal(); }
    return d;
  }
  function closeModal(d) {
    if (!d || !d.open || d.classList.contains("is-closing")) return;
    var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) { d.close(); return; }
    d.classList.add("is-closing");
    setTimeout(function () { d.classList.remove("is-closing"); d.close(); }, 150);
  }

  // ---------- Confirm (presentation only) ----------
  // Behaviour stays Administrate's: links/buttons carry data-turbo-confirm and Turbo
  // asks for confirmation. We only swap the browser's native confirm() for a styled
  // dialog through Turbo's official hook. Without Turbo nothing changes.
  function styledConfirm(message) {
    var d = document.getElementById("atu-confirm");
    if (!d || typeof d.showModal !== "function") return Promise.resolve(window.confirm(message));
    d.querySelector("[data-atu-confirm-message]").textContent = message;
    return new Promise(function (resolve) {
      function finish(ok) {
        d.removeEventListener("cancel", onCancel);
        accept.removeEventListener("click", onAccept);
        cancel.removeEventListener("click", onCancelClick);
        closeModal(d);
        resolve(ok);
      }
      var accept = d.querySelector("[data-atu-confirm-accept]");
      var cancel = d.querySelector("[data-atu-confirm-cancel]");
      function onAccept() { finish(true); }
      function onCancelClick() { finish(false); }
      function onCancel(e) { e.preventDefault(); finish(false); }   // Esc
      accept.addEventListener("click", onAccept);
      cancel.addEventListener("click", onCancelClick);
      d.addEventListener("cancel", onCancel);
      openModal(d);
      cancel.focus();
    });
  }
  function registerConfirm() {
    var T = window.Turbo;
    if (!T) return;
    if (T.config && T.config.forms && "confirm" in T.config.forms) T.config.forms.confirm = styledConfirm;
    else if (typeof T.setConfirmMethod === "function") T.setConfirmMethod(styledConfirm);
  }

  // ---------- Click delegation ----------
  document.addEventListener("click", function (e) {
    var t = e.target;
    var el;

    if ((el = t.closest("[data-atu-mode]"))) { save({ mode: el.dataset.atuMode }); applyPrefs(); return; }

    if ((el = t.closest("[data-atu-sidebar-toggle]"))) {
      if (window.innerWidth <= 960) {
        root.dataset.sidebar = root.dataset.sidebar === "open" ? "" : "open";
      } else {
        var collapsed = root.dataset.sidebar === "collapsed";
        root.dataset.sidebar = collapsed ? "" : "collapsed";
        save({ sidebar: collapsed ? "" : "collapsed" });
      }
      return;
    }

    // Opt-in modal helper (atu_modal / atu_modal_trigger)
    if ((el = t.closest("[data-atu-modal-open]"))) { e.preventDefault(); openModal(el.dataset.atuModalOpen); return; }
    if ((el = t.closest("[data-atu-modal-close]"))) { closeModal(el.closest("dialog")); return; }
    if (t.matches("dialog.atu-modal") && !t.hasAttribute("data-atu-static")) { closeModal(t); return; }  // backdrop

    if ((el = t.closest("[data-atu-dismiss]"))) { var n = el.closest(".atu-alert"); if (n) n.remove(); return; }

    document.querySelectorAll("details[data-atu-menu][open]").forEach(function (m) { if (!m.contains(t)) m.open = false; });
  });
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") document.querySelectorAll("details[data-atu-menu][open]").forEach(function (m) { m.open = false; });
  });

  // ---------- Charts ----------
  var charts = [];
  function cssVar(name) { return getComputedStyle(root).getPropertyValue(name).trim(); }
  function palette() { return [1, 2, 3, 4, 5, 6, 7, 8].map(function (i) { return cssVar("--atu-chart-" + i); }); }
  function alpha(hex, a) {
    var m = /^#?([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i.exec(hex);
    return m ? "rgba(" + parseInt(m[1], 16) + "," + parseInt(m[2], 16) + "," + parseInt(m[3], 16) + "," + a + ")" : hex;
  }
  var locale = root.dataset.atuLocale || undefined;
  function fmt(v, compact) {
    var n = Number(v);
    if (!isFinite(n)) return v;
    try { return new Intl.NumberFormat(locale, compact ? { notation: "compact", maximumFractionDigits: 1 } : { maximumFractionDigits: 2 }).format(n); }
    catch (e) { return n.toLocaleString(); }
  }

  function buildConfig(spec) {
    var colors = palette();
    var circular = spec.type === "doughnut" || spec.type === "pie";
    var text = cssVar("--atu-muted"), grid = cssVar("--atu-chart-grid"), surface = cssVar("--atu-surface");
    var font = cssVar("--atu-font");
    var datasets = spec.datasets.map(function (ds, i) {
      var c = colors[i % colors.length];
      var type = ds.type || spec.type;
      var area = type === "area";
      var out = Object.assign({}, ds, { type: area ? "line" : type });
      if (circular) {
        out.backgroundColor = ds.backgroundColor || ds.data.map(function (_, j) { return colors[j % colors.length]; });
        out.borderColor = surface; out.borderWidth = 2; out.hoverOffset = 4;
      } else if (out.type === "line") {
        out.borderColor = ds.borderColor || c; out.backgroundColor = ds.backgroundColor || alpha(c, area ? 0.08 : 1);
        out.fill = area; out.tension = 0.3; out.borderWidth = 1.75; out.pointRadius = 0; out.pointHoverRadius = 3.5;
        out.pointHoverBackgroundColor = c; out.pointHoverBorderColor = surface; out.pointHoverBorderWidth = 2;
      } else {
        out.backgroundColor = ds.backgroundColor || c; out.hoverBackgroundColor = alpha(c, 0.85);
        out.borderRadius = 2; out.maxBarThickness = 26; out.categoryPercentage = 0.7; out.barPercentage = 0.9;
      }
      return out;
    });
    var cfg = {
      type: spec.type === "area" ? "line" : spec.type,
      data: { labels: spec.labels, datasets: datasets },
      options: {
        responsive: true, maintainAspectRatio: false, animation: { duration: 350 },
        layout: { padding: { top: 4 } },
        interaction: { mode: circular ? "nearest" : "index", intersect: circular },
        cutout: spec.type === "doughnut" ? "72%" : undefined,
        plugins: {
          legend: {
            position: circular ? "right" : "top", align: "start",
            labels: { color: text, boxWidth: 10, boxHeight: 10, padding: 16, font: { family: font, size: 12 } }
          },
          tooltip: {
            backgroundColor: cssVar("--atu-text"), titleColor: cssVar("--atu-bg"), bodyColor: cssVar("--atu-bg"),
            padding: { x: 10, y: 8 }, cornerRadius: 6, boxPadding: 5, boxWidth: 8, boxHeight: 8, usePointStyle: false,
            titleFont: { family: font, size: 12, weight: "500" }, bodyFont: { family: font, size: 12 },
            callbacks: {
              label: function (ctx) {
                var v = ctx.parsed && typeof ctx.parsed === "object" ? ctx.parsed.y : ctx.parsed;
                return " " + (ctx.dataset.label || ctx.label) + "  " + fmt(v, false);
              }
            }
          }
        },
        scales: circular ? {} : {
          x: { grid: { display: false }, border: { color: grid }, ticks: { color: text, font: { family: font, size: 11.5 }, maxRotation: 0 } },
          y: {
            beginAtZero: true,
            grid: { color: grid, drawTicks: false }, border: { display: false, dash: [3, 3] },
            ticks: { color: text, padding: 8, font: { family: font, size: 11.5 }, maxTicksLimit: 6, callback: function (v) { return fmt(v, true); } }
          }
        }
      }
    };
    // Secondary axes declared by the caller inherit the same styling.
    Object.keys((spec.options && spec.options.scales) || {}).forEach(function (k) {
      if (k === "x" || k === "y") return;
      cfg.options.scales[k] = { border: { display: false }, grid: { display: false }, ticks: { color: text, font: { family: font, size: 11.5 }, maxTicksLimit: 6, callback: function (v) { return fmt(v, true); } } };
    });
    return deepMerge(cfg, { options: spec.options || {} });
  }
  function deepMerge(a, b) {
    Object.keys(b).forEach(function (k) {
      if (b[k] && typeof b[k] === "object" && !Array.isArray(b[k]) && a[k] && typeof a[k] === "object") deepMerge(a[k], b[k]);
      else a[k] = b[k];
    });
    return a;
  }
  function destroyCharts() { charts.forEach(function (c) { c.destroy(); }); charts = []; }
  function renderCharts(attempt) {
    var nodes = document.querySelectorAll("canvas[data-atu-chart]");
    if (!nodes.length) return;
    if (!window.Chart) { if ((attempt || 0) < 60) setTimeout(function () { renderCharts((attempt || 0) + 1); }, 50); return; }
    destroyCharts();
    nodes.forEach(function (canvas) {
      try { charts.push(new window.Chart(canvas, buildConfig(JSON.parse(canvas.dataset.atuChart)))); }
      catch (err) { console.error("[administrate_theme_ui] chart failed", err); }
    });
  }

  // ---------- Boot ----------
  function boot() {
    if (root.dataset.sidebar === "open") root.dataset.sidebar = "";
    syncSwitcher();
    registerConfirm();
    (document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve()).then(function () { renderCharts(); });
  }
  document.addEventListener("DOMContentLoaded", boot);
  document.addEventListener("turbo:load", boot);
  document.addEventListener("turbolinks:load", boot);
  document.addEventListener("turbo:before-cache", destroyCharts);

  window.AdministrateThemeUi = { openModal: openModal, closeModal: closeModal, renderCharts: renderCharts, applyPrefs: applyPrefs };
})();
