import puppeteer from "puppeteer-core";
const U = process.env.APP_URL || "http://localhost:3999", OUT = process.argv[2];
const b = await puppeteer.launch({ executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", headless: "new" });
async function shot(name, path, theme, mode, before, vp = { width: 1440, height: 900 }) {
  const p = await b.newPage();
  const errs = []; p.on("pageerror", e => errs.push(e.message));
  await p.setViewport(vp);
  await p.evaluateOnNewDocument((t, m) => localStorage.setItem("atu:prefs", JSON.stringify({ theme: t, mode: m })), theme, mode);
  await p.goto(U + path, { waitUntil: "networkidle0" });
  await p.evaluate(async () => { await document.fonts.load('12px "ATU Plex Sans"'); await document.fonts.load('600 12px "ATU Serif"'); });
  if (before) await before(p);
  await new Promise(r => setTimeout(r, 400));
  await p.screenshot({ path: `${OUT}/${name}.png` });
  console.log(name, errs.length ? "ERR " + errs.join("|") : "ok");
  await p.close();
}
await shot("legacy-graphite", "/admin/legacy", "graphite", "light");
await shot("legacy-ledger-dark", "/admin/legacy", "ledger", "dark");
await shot("usermenu-graphite", "/admin/loan_requests", "graphite", "light", p => p.click(".atu-user__trigger"));
await shot("usermenu-ledger", "/admin/loan_requests", "ledger", "light", p => p.click(".atu-user__trigger"));
await b.close();
