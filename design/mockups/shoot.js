// Screenshot every element with an id inside .mock figures to <outdir>/<id>.png (2x).
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const [, , html, outdir] = process.argv;
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1200, height: 900 }, deviceScaleFactor: 2 });
  await page.goto('file://' + path.resolve(html));
  await page.evaluate(() => document.fonts.ready);
  const ids = await page.$$eval('figure.mock > [id]', els => els.map(e => e.id));
  for (const id of ids) {
    await page.locator('#' + id).screenshot({ path: path.join(outdir, id + '.png') });
  }
  await browser.close();
  console.log('shots', ids.length);
})().catch(e => { console.error(e); process.exit(1); });
