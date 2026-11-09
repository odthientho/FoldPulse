// Render an HTML file to PDF with headless Chromium (preinstalled Playwright).
// Usage: node render.js in.html out.pdf '<header-json|null>'
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const [, , input, output, headerJson] = process.argv;
  const header = JSON.parse(headerJson || 'null');
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('file://' + path.resolve(input), { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  const font = 'font-family: Inter, sans-serif; font-size: 7.5pt; color: #5B6472; width: 100%; padding: 0 16mm;';
  await page.pdf({
    path: output,
    format: 'A4',
    printBackground: true,
    displayHeaderFooter: !!header,
    headerTemplate: header ? `<div style="${font} display:flex; justify-content:space-between; border-bottom: 0.5pt solid #C9D3E3; padding-bottom: 2mm; margin: 0 16mm;"><span style="color:#0B1B33;font-weight:600">${header.title}</span><span>${header.version}</span></div>` : '<span></span>',
    footerTemplate: header ? `<div style="${font} display:flex; justify-content:space-between; margin: 0 16mm; padding: 0;"><span>FoldPulse — Every Fold. Every Beat.</span><span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span></div>` : '<span></span>',
    margin: header ? { top: '22mm', bottom: '18mm', left: '16mm', right: '16mm' } : { top: '0', bottom: '0', left: '0', right: '0' },
  });
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
