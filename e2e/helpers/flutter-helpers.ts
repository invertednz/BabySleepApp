import { Page, Locator, expect } from "@playwright/test";

/**
 * Flutter Web Testing Helpers
 *
 * Flutter web (HTML renderer) renders text as <flt-paragraph>/<flt-span> elements
 * inside a shadow DOM under <flt-glass-pane>. Playwright's locators pierce
 * open shadow DOMs by default, so getByText/getByRole work.
 *
 * Semantics must be explicitly enabled by clicking the "Enable accessibility" button.
 */

/** Wait for Flutter framework to fully initialize */
export async function waitForFlutterReady(
  page: Page,
  timeout = 30_000,
): Promise<void> {
  await page.waitForLoadState("networkidle", { timeout });

  // Wait for Flutter's main element to appear
  await page.waitForFunction(
    () => {
      const fv = document.querySelector("flutter-view");
      if (!fv) return false;
      const gp = fv.querySelector("flt-glass-pane");
      return gp && gp.shadowRoot && gp.shadowRoot.innerHTML.length > 100;
    },
    { timeout },
  );

  // Give Flutter a moment to settle
  await page.waitForTimeout(2000);
}

/** Enable Flutter semantics by clicking the accessibility button */
export async function enableSemantics(page: Page): Promise<void> {
  const enableBtn = page.locator(
    'flt-semantics-placeholder[aria-label="Enable accessibility"]',
  );
  if (await enableBtn.isVisible().catch(() => false)) {
    // Focus and press the button programmatically
    await page.evaluate(() => {
      const btn = document.querySelector(
        'flt-semantics-placeholder[aria-label="Enable accessibility"]',
      );
      if (btn) {
        (btn as HTMLElement).focus();
        (btn as HTMLElement).click();
      }
    });
    await page.waitForTimeout(1000);
  }
}

/**
 * Get all visible text from the Flutter app (shadow DOM included).
 * Traverses shadow roots to find all flt-span text content.
 */
export async function getPageText(page: Page): Promise<string> {
  return page.evaluate(() => {
    function collectText(node: Node): string {
      let text = "";
      if (node instanceof HTMLElement && node.shadowRoot) {
        text += collectText(node.shadowRoot);
      }
      for (const child of Array.from(node.childNodes)) {
        if (child.nodeType === Node.TEXT_NODE) {
          const t = child.textContent?.trim();
          if (t) text += t + " ";
        } else if (child instanceof HTMLElement) {
          // Skip style/script elements
          if (
            child.tagName === "STYLE" ||
            child.tagName === "SCRIPT" ||
            child.tagName === "FLT-TEXT-EDITING-STYLESHEET"
          ) {
            continue;
          }
          text += collectText(child);
        }
      }
      return text;
    }
    return collectText(document.body).replace(/\s+/g, " ").trim();
  });
}

/**
 * Find a clickable Flutter element by its text.
 * Uses Playwright's shadow-piercing locators.
 */
export function flutterButton(page: Page, label: string): Locator {
  // Playwright getByText and getByRole pierce shadow DOM
  return page
    .getByRole("button", { name: label })
    .or(page.getByText(label, { exact: true }))
    .first();
}

/** Click a Flutter button/touchable element by text.
 * Strategy: Find the flt-span elements that compose the button text,
 * use dispatchEvent to simulate a pointer interaction directly on the
 * flutter-view, at the coordinates of the text.
 */
export async function tapFlutterButton(
  page: Page,
  text: string,
): Promise<void> {
  // Find text coordinates by locating flt-span elements in shadow DOM
  const findButtonCoords = async () => {
    return page.evaluate((buttonText) => {
      function findAllSpansInShadow(root: Node, spans: HTMLElement[]): void {
        if (root instanceof HTMLElement && root.shadowRoot) {
          findAllSpansInShadow(root.shadowRoot, spans);
        }
        for (const child of Array.from(root.childNodes)) {
          if (child instanceof HTMLElement) {
            if (child.tagName === "FLT-SPAN") {
              spans.push(child);
            }
            findAllSpansInShadow(child, spans);
          }
        }
      }

      // Collect all flt-span elements
      const allSpans: HTMLElement[] = [];
      findAllSpansInShadow(document.body, allSpans);

      // Strategy 1: Find a single span that matches (for single-word buttons)
      for (const span of allSpans) {
        if (span.textContent?.trim() === buttonText) {
          const rect = span.getBoundingClientRect();
          if (rect.width > 0 && rect.height > 0) {
            return {
              x: rect.x + rect.width / 2,
              y: rect.y + rect.height / 2,
              needsScroll: rect.y > window.innerHeight - 50 || rect.y < 0,
            };
          }
        }
      }

      // Strategy 2: Find a paragraph parent that matches (for multi-word buttons)
      // Group spans by their parent paragraph
      const paragraphMap = new Map<HTMLElement, HTMLElement[]>();
      for (const span of allSpans) {
        let p = span.parentElement;
        while (p && p.tagName !== "FLT-PARAGRAPH") {
          p = p.parentElement;
        }
        if (p) {
          if (!paragraphMap.has(p)) paragraphMap.set(p, []);
          paragraphMap.get(p)!.push(span);
        }
      }

      for (const [, spans] of paragraphMap) {
        // Normalize: collapse whitespace to single spaces for matching
        const paraText = spans
          .map((s) => s.textContent?.trim() || "")
          .filter((t) => t.length > 0)
          .join(" ");
        if (
          paraText === buttonText ||
          paraText.replace(/\s+/g, " ") === buttonText
        ) {
          // Get bounding box from first and last visible spans
          const visibleSpans = spans.filter((s) => {
            const r = s.getBoundingClientRect();
            return r.width > 0 && r.height > 0;
          });
          if (visibleSpans.length > 0) {
            const first = visibleSpans[0].getBoundingClientRect();
            const last =
              visibleSpans[visibleSpans.length - 1].getBoundingClientRect();
            const y = first.y + first.height / 2;
            return {
              x: (first.x + last.x + last.width) / 2,
              y,
              needsScroll: y > window.innerHeight - 50 || y < 0,
            };
          }
        }
      }

      return null;
    }, text);
  };

  let coords = await findButtonCoords();

  // If button is near the bottom edge, scroll it into better view
  if (coords?.needsScroll) {
    await page.mouse.wheel(0, 200);
    await page.waitForTimeout(500);
    coords = await findButtonCoords();
  }

  if (coords) {
    await page.mouse.click(coords.x, coords.y);
    await page.waitForTimeout(1000);
    return;
  }

  // Fallback: Playwright's getByText with force click
  const textEl = page.getByText(text, { exact: true }).first();
  if (await textEl.isVisible({ timeout: 3000 }).catch(() => false)) {
    await textEl.click({ force: true });
    await page.waitForTimeout(1000);
    return;
  }

  // Fallback: Flutter sometimes renders buttons as canvas elements (especially after state changes).
  // Look for a large canvas near the bottom of the viewport.
  const canvasCoords = await page.evaluate(() => {
    function findCanvases(
      root: Node,
      results: { x: number; y: number; w: number; h: number }[],
    ): void {
      if (root instanceof HTMLElement && root.shadowRoot)
        findCanvases(root.shadowRoot, results);
      for (const child of Array.from(root.childNodes)) {
        if (child instanceof HTMLElement) {
          if (child.tagName === "CANVAS") {
            const rect = child.getBoundingClientRect();
            // Look for button-sized canvas near the bottom
            if (
              rect.width > 100 &&
              rect.height > 30 &&
              rect.height < 150 &&
              rect.y > window.innerHeight * 0.7
            ) {
              results.push({
                x: rect.x + rect.width / 2,
                y: rect.y + rect.height / 2,
                w: rect.width,
                h: rect.height,
              });
            }
          }
          findCanvases(child, results);
        }
      }
    }
    const results: { x: number; y: number; w: number; h: number }[] = [];
    findCanvases(document.body, results);
    // Return the bottom-most matching canvas
    return results.length > 0 ? results[results.length - 1] : null;
  });

  if (canvasCoords) {
    await page.mouse.click(canvasCoords.x, canvasCoords.y);
    await page.waitForTimeout(1000);
    return;
  }

  throw new Error(`Could not find button with text: "${text}"`);
}

/** Select a card/option in a Flutter selection list by text.
 * Uses same span-based coordinate approach as tapFlutterButton.
 */
export async function selectFlutterOption(
  page: Page,
  optionText: string,
): Promise<void> {
  // Reuse tapFlutterButton logic but with shorter wait
  const coords = await page.evaluate((targetText) => {
    function findAllSpansInShadow(root: Node, spans: HTMLElement[]): void {
      if (root instanceof HTMLElement && root.shadowRoot) {
        findAllSpansInShadow(root.shadowRoot, spans);
      }
      for (const child of Array.from(root.childNodes)) {
        if (child instanceof HTMLElement) {
          if (child.tagName === "FLT-SPAN") spans.push(child);
          findAllSpansInShadow(child, spans);
        }
      }
    }

    const allSpans: HTMLElement[] = [];
    findAllSpansInShadow(document.body, allSpans);

    // Try single span match
    for (const span of allSpans) {
      if (span.textContent?.trim() === targetText) {
        const rect = span.getBoundingClientRect();
        if (rect.width > 0 && rect.height > 0) {
          return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
        }
      }
    }

    // Try paragraph match (multi-word)
    const paragraphMap = new Map<HTMLElement, HTMLElement[]>();
    for (const span of allSpans) {
      let p = span.parentElement;
      while (p && p.tagName !== "FLT-PARAGRAPH") p = p.parentElement;
      if (p) {
        if (!paragraphMap.has(p)) paragraphMap.set(p, []);
        paragraphMap.get(p)!.push(span);
      }
    }

    for (const [, spans] of paragraphMap) {
      const paraText = spans
        .map((s) => s.textContent?.trim() || "")
        .filter((t) => t.length > 0)
        .join(" ");
      if (
        paraText === targetText ||
        paraText.replace(/\s+/g, " ") === targetText
      ) {
        const visibleSpans = spans.filter((s) => {
          const r = s.getBoundingClientRect();
          return r.width > 0 && r.height > 0;
        });
        if (visibleSpans.length > 0) {
          const first = visibleSpans[0].getBoundingClientRect();
          const last =
            visibleSpans[visibleSpans.length - 1].getBoundingClientRect();
          return {
            x: (first.x + last.x + last.width) / 2,
            y: first.y + first.height / 2,
          };
        }
      }
    }

    return null;
  }, optionText);

  if (coords) {
    await page.mouse.click(coords.x, coords.y);
    await page.waitForTimeout(500);
    return;
  }

  // Fallback
  const textEl = page.getByText(optionText, { exact: true }).first();
  if (await textEl.isVisible({ timeout: 3000 }).catch(() => false)) {
    await textEl.click({ force: true });
    await page.waitForTimeout(500);
  }
}

/** Check if text is present in the Flutter page */
export async function expectFlutterText(
  page: Page,
  text: string,
): Promise<void> {
  const pageText = await getPageText(page);
  expect(pageText).toContain(text);
}

/** Alias for expectFlutterText */
export async function expectFlutterTextContent(
  page: Page,
  text: string,
): Promise<void> {
  // Retry a few times since Flutter may still be animating
  for (let i = 0; i < 5; i++) {
    const pageText = await getPageText(page);
    if (pageText.includes(text)) return;
    await page.waitForTimeout(1000);
  }
  const finalText = await getPageText(page);
  expect(finalText).toContain(text);
}

/** Wait for a Flutter page transition to complete */
export async function waitForPageTransition(
  page: Page,
  expectedText: string,
): Promise<void> {
  await page.waitForTimeout(800);
  await expectFlutterTextContent(page, expectedText);
}

/** Find a Flutter text input field */
export function flutterTextField(page: Page, label?: string): Locator {
  if (label) {
    return page
      .getByRole("textbox", { name: label })
      .or(page.locator(`input[aria-label="${label}"]`))
      .first();
  }
  return page.locator("input, textarea").first();
}

/** Type into a Flutter text field */
export async function fillFlutterField(
  page: Page,
  label: string,
  value: string,
): Promise<void> {
  const field = flutterTextField(page, label);
  await field.waitFor({ state: "visible", timeout: 10_000 });
  await field.click();
  await field.fill(value);
}

/** Take a named screenshot */
export async function takeScreenshot(page: Page, name: string): Promise<void> {
  await page.screenshot({
    path: `test-results/screenshots/${name}.png`,
    fullPage: true,
  });
}

/** Scroll down in the Flutter app */
export async function scrollDown(page: Page, pixels = 300): Promise<void> {
  await page.mouse.wheel(0, pixels);
  await page.waitForTimeout(500);
}

/** Generate a unique test email */
export function testEmail(): string {
  return `test_${Date.now()}@babysteps-test.com`;
}

/** Generate a test password */
export function testPassword(): string {
  return "TestPass123!";
}

/** Navigate through onboarding screens by clicking "Continue", "Next", or "Get Started" */
export async function advanceOnboarding(page: Page, clicks = 1): Promise<void> {
  for (let i = 0; i < clicks; i++) {
    const pageText = await getPageText(page);

    // Try buttons in priority order (specific before generic)
    const buttonPatterns: [string, string][] = [
      ["I Want These Results", "I Want These Results"],
      ["I ' m Ready", "I ' m Ready"],
      ["Let ' s Do This Together", "Let ' s Do This Together"],
      ["Let ' s Build Your Plan", "Let ' s Build Your Plan"],
      ["Show Me My Plan", "Show Me My Plan"],
      ["Get Started", "Get Started"],
      ["Continue", "Continue"],
      ["Next", "Next"],
    ];
    for (const [search, click] of buttonPatterns) {
      if (pageText.includes(search)) {
        await tapFlutterButton(page, click);
        break;
      }
    }
    await page.waitForTimeout(500);
  }
}

/** Wait for loading indicators to finish */
export async function waitForLoading(page: Page): Promise<void> {
  try {
    await page.waitForFunction(
      () => {
        const spinners = document.querySelectorAll('[role="progressbar"]');
        return spinners.length === 0;
      },
      { timeout: 10_000 },
    );
  } catch {
    // No spinner found
  }
}
