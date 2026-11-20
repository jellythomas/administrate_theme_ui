// Browser checks: themes/modes + Administrate behaviour rendered by the theme.
// APP_URL=http://localhost:3999 node e2e.mjs   (NO_TURBO=1 for hosts that replace Administrate's JS with jQuery/UJS)
import puppeteer from "puppeteer-core";
const U = process.env.APP_URL || "http://localhost:3999";
const TURBO = !process.env.NO_TURBO;
const ok = (c, m) => { console.log((c ? "PASS " : "FAIL ") + m); if (!c) process.exitCode = 1; };
const wait = (ms) => new Promise(r => setTimeout(r, ms));
const b = await puppeteer.launch({ executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", headless: "new" });
const p = await b.newPage();
const errors = []; p.on("pageerror", e => errors.push(e.message));
await p.setViewport({ width: 1280, height: 900 });
await p.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "light" }]);
await p.goto(`${U}/admin/stats`, { waitUntil: "networkidle0" });
const attr = (n) => p.evaluate((n) => document.documentElement.dataset[n], n);

// --- Theme / mode (the gem's own concern)
ok(await attr("theme") === "graphite" && await attr("mode") === "light", "default theme graphite, system->light");
ok(await p.evaluate(async () => (await document.fonts.load('12px "ATU Plex Sans"')).length > 0), "IBM Plex webfont loaded");
await wait(300);
ok(await p.evaluate(() => document.querySelectorAll("canvas[data-atu-chart]").length === 1 && !!window.Chart), "chart rendered");
ok(await p.$$eval(".atu-dist__list li", l => l.length) > 0, "distribution rendered");
await p.click('[data-atu-mode="dark"]');
await p.select("[data-atu-theme-select]", "ledger");
ok(await attr("mode") === "dark" && await attr("theme") === "ledger", "mode + theme switch apply");
await p.reload({ waitUntil: "networkidle0" });
ok(await attr("mode") === "dark" && await attr("theme") === "ledger", "prefs persist after reload");
ok(await p.evaluate(async () => (await document.fonts.load('600 12px "ATU Serif"')).length > 0), "Ledger serif webfont loaded");
await p.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "dark" }]);
await p.click('[data-atu-mode="system"]');
ok(await attr("mode") === "dark", "system follows OS dark");
await p.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "light" }]);
await wait(100);
ok(await attr("mode") === "light", "system reacts live to OS change");

// --- Opt-in modal helper
await p.click('[data-atu-modal-open="export-modal"]');
ok(await p.$eval("#export-modal", d => d.open), "modal opens");
await p.mouse.click(10, 10); await wait(250);
ok(!(await p.$eval("#export-modal", d => d.open)), "backdrop click closes passive modal");
await p.click(".atu-topbar [data-atu-sidebar-toggle]");
ok(await attr("sidebar") === "collapsed", "sidebar collapses");
await p.click(".atu-topbar [data-atu-sidebar-toggle]");

// --- Administrate behaviour: destroy asks via data-(turbo-)confirm
await p.goto(`${U}/admin/loan_requests`, { waitUntil: "networkidle0" });
const firstId = await p.$eval("tbody tr td", td => td.textContent.trim());
const del = "tbody tr a.atu-iconbtn--danger";
ok(await p.$eval(del, a => a.dataset.turboConfirm === "Are you sure?" && a.dataset.turboMethod === "delete" && a.dataset.confirm === "Are you sure?"), "destroy uses Administrate's confirm message + Rails method attrs");
if (TURBO) {
  await p.click(del); await wait(200);
  ok(await p.$eval("#atu-confirm", d => d.open), "Turbo confirm shown in styled dialog");
  ok((await p.$eval("[data-atu-confirm-message]", e => e.textContent)) === "Are you sure?", "dialog shows Administrate's message");
  ok(await p.evaluate(() => document.activeElement.matches("[data-atu-confirm-cancel]")), "Cancel has initial focus");
  ok(p.url().endsWith("/admin/loan_requests"), "row click did not navigate away");
  await p.click("[data-atu-confirm-cancel]"); await wait(300);
  ok(await p.$eval("tbody tr td", td => td.textContent.trim()) === firstId, "cancel keeps record");
  await p.click(del); await wait(200);
  await Promise.all([p.waitForNavigation({ waitUntil: "networkidle0" }), p.click("[data-atu-confirm-accept]")]);
  await wait(400);
} else {
  p.once("dialog", d => d.accept());   // jquery_ujs uses the browser's confirm()
  await Promise.all([p.waitForNavigation({ waitUntil: "networkidle0" }), p.click(del)]);
}
ok(await p.$eval("tbody tr td", td => td.textContent.trim()) !== firstId, "accept deletes record");
ok(await p.$(".atu-flashes .atu-alert--success") !== null, "flash rendered inline (persistent)");

// --- Administrate behaviour: row click opens the record (Stimulus table controller)
if (TURBO) {
  await Promise.all([p.waitForNavigation(), p.click("tbody tr td:nth-child(3)")]);
  ok(/\/admin\/loan_requests\/\d+$/.test(p.url()), "row click opens record");
}

// --- Administrate behaviour: Kaminari pagination + per_page param passthrough
await p.goto(`${U}/admin/loan_requests?per_page=10`, { waitUntil: "networkidle0" });
ok((await p.$$("tbody tr")).length === 10, "?per_page= honoured as in Administrate");
ok(await p.$("nav.atu-pages .atu-page.is-current[aria-current=page]") !== null, "Kaminari pagination with current page");
await Promise.all([p.waitForNavigation({ waitUntil: "networkidle0" }), p.click("nav.atu-pages a[rel=next]")]);
ok((await p.$eval(".atu-pager__range", e => e.textContent)).includes("11–20") && p.url().includes("_page=2"), "next page via Kaminari link (_page param)");

// --- Administrate behaviour: search with filter syntax + help popover
await p.goto(`${U}/admin/loan_requests`, { waitUntil: "networkidle0" });
ok(await p.$('[data-controller="tooltip"] [popover]') !== null, "filter help popover (Administrate markup) present");
await p.type("#search", "rejected:");
await Promise.all([p.waitForNavigation({ waitUntil: "networkidle0" }), p.keyboard.press("Enter")]);
const statuses = await p.$$eval("tbody .atu-badge", els => [...new Set(els.map(e => e.textContent.trim()))]);
ok(statuses.length === 1 && statuses[0] === "Rejected", "filter search returns only Rejected");

await p.goto(`${U}/admin/loan_requests/new`, { waitUntil: "networkidle0" });
if (TURBO) ok(await p.$(".selectize-control") !== null, "belongs_to select enhanced by selectize");
ok(await p.$(".atu-affix__unit") !== null, "Field::Money form shows unit affix");

ok(errors.length === 0, "no JS errors " + JSON.stringify(errors));
await b.close();
