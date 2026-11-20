import puppeteer from "puppeteer-core";
const U = process.env.APP_URL || "http://localhost:3999";
const ok = (c, m) => { console.log((c ? "PASS " : "FAIL ") + m); if (!c) process.exitCode = 1; };
const wait = (ms) => new Promise(r => setTimeout(r, ms));
const b = await puppeteer.launch({ executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", headless: "new" });
const p = await b.newPage();
const errors = []; p.on("pageerror", e => errors.push(e.message));
await p.setViewport({ width: 1280, height: 900 });
await p.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "light" }]);
await p.goto(`${U}/admin/stats`, { waitUntil: "networkidle0" });
const attr = (n) => p.evaluate((n) => document.documentElement.dataset[n], n);
ok(await attr("theme") === "graphite" && await attr("mode") === "light", "default theme graphite, system->light");
ok(await p.evaluate(async () => (await document.fonts.load('12px "ATU Plex Sans"')).length > 0 && document.fonts.check('12px "ATU Plex Sans"')), "IBM Plex webfont loaded");
await wait(300);
ok(await p.evaluate(() => document.querySelectorAll("canvas[data-atu-chart]").length === 1 && !!window.Chart), "chart rendered");
ok(await p.$$eval(".atu-dist__list li", l => l.length) > 0, "distribution rendered");

await p.click('[data-atu-mode="dark"]');
await p.select("[data-atu-theme-select]", "ledger");
ok(await attr("mode") === "dark" && await attr("theme") === "ledger", "mode + theme switch apply");
await p.reload({ waitUntil: "networkidle0" });
ok(await attr("mode") === "dark" && await attr("theme") === "ledger", "prefs persist after reload");
ok(await p.evaluate(async () => (await document.fonts.load('600 12px "ATU Serif"')).length > 0 && document.fonts.check('600 12px "ATU Serif"')), "Ledger serif webfont loaded");
await p.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "dark" }]);
await p.click('[data-atu-mode="system"]');
ok(await attr("mode") === "dark", "system follows OS dark");
await p.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "light" }]);
await wait(100);
ok(await attr("mode") === "light", "system reacts live to OS change");

// Passive modal
await p.click('[data-atu-modal-open="export-modal"]');
ok(await p.$eval("#export-modal", d => d.open), "modal opens");
await p.mouse.click(10, 10); await wait(250);
ok(!(await p.$eval("#export-modal", d => d.open)), "backdrop click closes passive modal");
await p.click('[data-atu-modal-open="export-modal"]');
await p.keyboard.press("Escape"); await wait(100);
ok(!(await p.$eval("#export-modal", d => d.open)), "Esc closes modal");

await p.click(".atu-topbar [data-atu-sidebar-toggle]");
ok(await attr("sidebar") === "collapsed", "sidebar collapses");
await p.click(".atu-topbar [data-atu-sidebar-toggle]");

// Destructive confirm
await p.goto(`${U}/admin/loan_requests`, { waitUntil: "networkidle0" });
const firstId = await p.$eval("tbody tr td", td => td.textContent.trim());
await p.click("tbody tr form[data-atu-confirm] button");
ok(await p.$eval("#atu-confirm", d => d.open), "confirm dialog opens on delete");
ok(await p.evaluate(() => document.activeElement.matches("[data-atu-confirm-cancel]")), "Cancel has initial focus");
ok((await p.$eval("[data-atu-confirm-accept]", el => el.textContent)).startsWith("Delete loan request"), "action label is verb + noun");
await p.mouse.click(10, 10); await wait(250);
ok(await p.$eval("#atu-confirm", d => d.open), "backdrop click does NOT close confirm");
await p.click("#atu-confirm [data-atu-confirm-cancel]"); await wait(300);
ok(await p.$eval("tbody tr td", td => td.textContent.trim()) === firstId, "cancel keeps record");

// Type-to-confirm via JS API
await p.evaluate(() => { window.__ok = false; AdministrateThemeUi.confirm({ message: "x", expect: "PT Maju Jaya" }, () => { window.__ok = true; }); });
ok(await p.$eval("[data-atu-confirm-accept]", el => el.disabled), "type-to-confirm keeps action disabled");
await p.type("[data-atu-confirm-input]", "PT Maju Jaya");
ok(!(await p.$eval("[data-atu-confirm-accept]", el => el.disabled)), "typing exact text enables action");
await p.keyboard.press("Enter"); await wait(250);
ok(await p.evaluate(() => window.__ok), "Enter accepts once matched");

await p.click("tbody tr form[data-atu-confirm] button");
await Promise.all([p.waitForNavigation({ waitUntil: "networkidle0" }), p.click("#atu-confirm [data-atu-confirm-accept]")]);
await p.waitForSelector(".atu-toast--success"); await wait(400);  // Turbo shows a cached preview first
ok(await p.$eval("tbody tr td", td => td.textContent.trim()) !== firstId, "accept deletes record");
ok(await p.$(".atu-toast--success") !== null, "success toast shown");

// Row click
await Promise.all([p.waitForNavigation(), p.click("tbody tr td:nth-child(3)")]);
ok(/\/admin\/loan_requests\/\d+$/.test(p.url()), "row click opens record");

// Pagination bar
await p.goto(`${U}/admin/loan_requests`, { waitUntil: "networkidle0" });
ok(await p.$eval(".atu-pager__btn[aria-label='Previous page']", e => e.getAttribute("aria-disabled") === "true"), "Prev disabled on first page");
await Promise.all([p.waitForNavigation({ waitUntil: "networkidle0" }), p.select("#atu-per-page", "10")]);
ok(p.url().includes("per_page=10") && (await p.$$("tbody tr")).length === 10, "rows-per-page reloads with 10 rows");
await Promise.all([p.waitForNavigation({ waitUntil: "networkidle0" }), p.click("a.atu-pager__btn[aria-label='Next page']")]);
ok((await p.$eval(".atu-pager__range", e => e.textContent)).includes("11–20"), "next page shows 11-20 and keeps per_page");
await Promise.all([p.waitForNavigation({ waitUntil: "networkidle0" }), p.select("#atu-page-jump", "4")]);
ok((await p.$eval(".atu-pager__range", e => e.textContent)).includes("31–40"), "page jump select works");

// Tabs + search shortcut
await Promise.all([p.waitForNavigation(), p.evaluate(() => [...document.querySelectorAll(".atu-tab")].find(a => a.textContent === "Rejected").click())]);
ok(p.url().includes("search=rejected%3A"), "filter tab applies filter");
const statuses = await p.$$eval("tbody .atu-badge", els => [...new Set(els.map(e => e.textContent.trim()))]);
ok(statuses.length === 1 && statuses[0] === "Rejected", "filtered rows all Rejected");
ok(await p.$eval(".atu-tab.is-active", e => e.textContent) === "Rejected", "active tab marked");
await p.click("h1"); await p.keyboard.press("/");
ok(await p.evaluate(() => document.activeElement.matches("[data-atu-search]")), "'/' focuses search");

await p.goto(`${U}/admin/loan_requests/new`, { waitUntil: "networkidle0" });
if (!process.env.NO_SELECTIZE) ok(await p.$(".selectize-control") !== null, "belongs_to select enhanced by selectize");
ok(await p.$(".atu-affix__unit") !== null, "Field::Money form shows unit affix");

await p.goto(`${U}/admin/loan_requests?per_page=100000`, { waitUntil: "networkidle0" });
ok((await p.$$("tbody tr")).length === 20, "unlisted per_page falls back to default (20)");

ok(errors.length === 0, "no JS errors " + JSON.stringify(errors));
await b.close();
