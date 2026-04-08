import { Page, expect } from "@playwright/test";

/**
 * Flutter Web Testing Helpers (CanvasKit renderer)
 *
 * Flutter web with CanvasKit renders everything on a <canvas>.
 * To interact with text and buttons, we must enable Flutter's semantics tree,
 * which creates a parallel DOM of <flt-semantics> and <span> elements.
 *
 * Flow: waitForFlutterReady() → enableSemantics() → then use getPageText/tap/etc.
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

  // Enable semantics so we get a DOM tree to interact with
  await enableSemantics(page);
}

/** Enable Flutter semantics by clicking the accessibility button */
export async function enableSemantics(page: Page): Promise<void> {
  const enabled = await page.evaluate(() => {
    const btn = document.querySelector(
      'flt-semantics-placeholder[aria-label="Enable accessibility"]',
    ) as HTMLElement;
    if (btn) {
      btn.click();
      return true;
    }
    return false;
  });

  if (enabled) {
    await page.waitForTimeout(1500);
  }
}

/**
 * Get all visible text from the Flutter app.
 * With CanvasKit + semantics enabled, text appears in <span> and <flt-semantics> elements.
 */
export async function getPageText(page: Page): Promise<string> {
  return page.evaluate(() => {
    const texts: string[] = [];
    const seen = new Set<string>();

    function collectFromNode(root: Node): void {
      if (root instanceof HTMLElement && root.shadowRoot) {
        collectFromNode(root.shadowRoot);
      }
      for (const child of Array.from(root.childNodes)) {
        if (child.nodeType === Node.TEXT_NODE) {
          const t = child.textContent?.trim();
          if (!t || t.length === 0) continue;
          // Skip hidden/measurement elements
          if (t.includes("typography measurement")) continue;
          const parent = child.parentElement;
          if (!parent) continue;
          const tag = parent.tagName;
          // Skip style/script
          if (
            tag === "STYLE" ||
            tag === "SCRIPT" ||
            tag === "FLT-TEXT-EDITING-STYLESHEET"
          )
            continue;
          // Skip hidden elements
          const style = window.getComputedStyle(parent);
          if (style.display === "none" || style.visibility === "hidden")
            continue;
          // Deduplicate (semantics tree can repeat text)
          if (!seen.has(t)) {
            seen.add(t);
            texts.push(t);
          }
        } else if (child instanceof HTMLElement) {
          collectFromNode(child);
        }
      }
    }

    collectFromNode(document.body);
    return texts.join(" ");
  });
}

/**
 * Click a Flutter button by its text label.
 * With CanvasKit + semantics, buttons are flt-semantics[role=button] with pointer-events:all.
 * We use Playwright's getByRole which works with the semantics tree.
 */
export async function tapFlutterButton(
  page: Page,
  text: string,
): Promise<void> {
  // Strategy 1: Playwright's getByRole (best for CanvasKit with semantics)
  const roleBtn = page.getByRole("button", { name: text });
  if (await roleBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
    await roleBtn.click({ force: true });
    await page.waitForTimeout(1000);
    return;
  }

  // Strategy 2: getByText with force click
  const textEl = page.getByText(text, { exact: true }).first();
  if (await textEl.isVisible({ timeout: 3000 }).catch(() => false)) {
    await textEl.click({ force: true });
    await page.waitForTimeout(1000);
    return;
  }

  // Strategy 3: Find flt-semantics element by text content and click at its coordinates
  const coords = await page.evaluate((buttonText) => {
    const all = document.querySelectorAll("flt-semantics");
    for (const el of Array.from(all)) {
      const content = el.textContent?.trim();
      if (content === buttonText || content?.includes(buttonText)) {
        const rect = (el as HTMLElement).getBoundingClientRect();
        if (rect.width > 0 && rect.height > 0) {
          return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
        }
      }
    }
    return null;
  }, text);

  if (coords) {
    await page.mouse.click(coords.x, coords.y);
    await page.waitForTimeout(1000);
    return;
  }

  throw new Error(`Could not find button with text: "${text}"`);
}

/** Select a card/option in a Flutter selection list by text.
 * Options may not be role=button, so we use text matching and coordinate-based clicking.
 */
export async function selectFlutterOption(
  page: Page,
  optionText: string,
): Promise<void> {
  // Strategy 1: Playwright getByText
  const textEl = page.getByText(optionText, { exact: false }).first();
  if (await textEl.isVisible({ timeout: 3000 }).catch(() => false)) {
    await textEl.click({ force: true });
    await page.waitForTimeout(500);
    return;
  }

  // Strategy 2: Find flt-semantics containing the text
  const coords = await page.evaluate((targetText) => {
    const all = document.querySelectorAll("flt-semantics");
    for (const el of Array.from(all)) {
      const content = el.textContent?.trim();
      if (content?.includes(targetText)) {
        const rect = (el as HTMLElement).getBoundingClientRect();
        if (rect.width > 0 && rect.height > 0) {
          return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
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

  throw new Error(`Could not find option with text: "${optionText}"`);
}

/** Assert that specific text is present on the page. Retries up to 5 times. */
export async function expectFlutterText(
  page: Page,
  text: string,
): Promise<void> {
  for (let i = 0; i < 5; i++) {
    const pageText = await getPageText(page);
    if (pageText.includes(text)) return;
    await page.waitForTimeout(1000);
  }
  const finalText = await getPageText(page);
  expect(finalText).toContain(text);
}

/** Wait for a Flutter page transition to complete, asserting expected text appears */
export async function waitForPageTransition(
  page: Page,
  expectedText: string,
  timeout = 10_000,
): Promise<void> {
  const startTime = Date.now();
  while (Date.now() - startTime < timeout) {
    const pageText = await getPageText(page);
    if (pageText.includes(expectedText)) return;
    await page.waitForTimeout(500);
  }
  // Final assertion that will fail with a clear message
  const finalText = await getPageText(page);
  expect(
    finalText,
    `Page transition timed out waiting for "${expectedText}"`,
  ).toContain(expectedText);
}

/** Type into a Flutter text field */
export async function fillFlutterField(
  page: Page,
  label: string,
  value: string,
): Promise<void> {
  const field = page
    .getByRole("textbox", { name: label })
    .or(page.locator(`input[aria-label="${label}"]`))
    .or(page.locator("input").first())
    .first();
  await field.waitFor({ state: "visible", timeout: 10_000 });
  await field.click();
  await field.fill(value);
}

/** Scroll down in the Flutter app.
 * Uses Playwright's native mouse API for a real drag gesture
 * that Flutter's CanvasKit event handler can intercept.
 */
export async function scrollDown(page: Page, pixels = 300): Promise<void> {
  const centerX = 195;
  const startY = 600;
  const endY = startY - pixels;
  const steps = 10;

  await page.mouse.move(centerX, startY);
  await page.mouse.down();
  for (let i = 1; i <= steps; i++) {
    const y = startY + (endY - startY) * (i / steps);
    await page.mouse.move(centerX, y, { steps: 1 });
    await page.waitForTimeout(30);
  }
  await page.mouse.up();
  await page.waitForTimeout(1000);
}

/**
 * Check if specific text is visible anywhere on the page, including after scrolling.
 * Uses Playwright's getByText which can find elements that getPageText() misses
 * (e.g., after scroll when semantics nodes haven't fully updated).
 */
export async function isTextVisible(
  page: Page,
  text: string,
): Promise<boolean> {
  return page
    .getByText(text, { exact: false })
    .first()
    .isVisible({ timeout: 3000 })
    .catch(() => false);
}

/**
 * Search Chrome's Accessibility Tree (via CDP) for a node whose name contains the given text.
 * This works even when Flutter CanvasKit doesn't expose text in the DOM after scrolling.
 * Returns the node's backendDOMNodeId if found, or null.
 */
export async function findInAccessibilityTree(
  page: Page,
  searchText: string,
): Promise<{ nodeId: number; name: string; role: string } | null> {
  const client = await page.context().newCDPSession(page);
  try {
    const { nodes } = await client.send("Accessibility.getFullAXTree");
    for (const node of nodes) {
      const name = node.name?.value || "";
      if (name.includes(searchText)) {
        return {
          nodeId: node.backendDOMNodeId,
          name,
          role: node.role?.value || "",
        };
      }
    }
    return null;
  } finally {
    await client.detach();
  }
}

/**
 * Click an element found via Chrome's Accessibility Tree (CDP).
 * Useful for clicking CanvasKit Flutter elements that aren't in the DOM
 * after scrolling (e.g., recommendation cards).
 */
export async function tapAccessibilityNode(
  page: Page,
  searchText: string,
): Promise<void> {
  const client = await page.context().newCDPSession(page);
  try {
    const { nodes } = await client.send("Accessibility.getFullAXTree");
    for (const node of nodes) {
      const name = node.name?.value || "";
      if (name.includes(searchText) && node.backendDOMNodeId) {
        // Get the DOM node's bounding box via CDP
        const { model } = await client.send("DOM.getBoxModel", {
          backendNodeId: node.backendDOMNodeId,
        });
        if (model) {
          // content quad: [x1,y1, x2,y2, x3,y3, x4,y4]
          const quad = model.content;
          const x = (quad[0] + quad[2] + quad[4] + quad[6]) / 4;
          const y = (quad[1] + quad[3] + quad[5] + quad[7]) / 4;
          await page.mouse.click(x, y);
          await page.waitForTimeout(1000);
          return;
        }
      }
    }
    throw new Error(
      `Could not find accessibility node with text: "${searchText}"`,
    );
  } finally {
    await client.detach();
  }
}

/** Take a named screenshot */
export async function takeScreenshot(page: Page, name: string): Promise<void> {
  await page.screenshot({
    path: `test-results/screenshots/${name}.png`,
    fullPage: true,
  });
}

/** Generate a unique test email */
export function testEmail(): string {
  return `test_${Date.now()}@babysteps-test.com`;
}

/** Generate a test password */
export function testPassword(): string {
  return "TestPass123!";
}

/** Navigate through onboarding screens by clicking the current screen's advance button */
export async function advanceOnboarding(page: Page, clicks = 1): Promise<void> {
  for (let i = 0; i < clicks; i++) {
    const pageText = await getPageText(page);

    const buttonPatterns = [
      "I Want These Results",
      "I ' m Ready",
      "Let ' s Do This Together",
      "Let ' s Build Your Plan",
      "Show Me My Plan",
      "Get Started",
      "Continue",
      "Next",
    ];
    let clicked = false;
    for (const btn of buttonPatterns) {
      if (pageText.includes(btn)) {
        await tapFlutterButton(page, btn);
        clicked = true;
        break;
      }
    }
    if (!clicked) {
      throw new Error(
        `No advance button found on screen with text: "${pageText.substring(0, 100)}..."`,
      );
    }
    await page.waitForTimeout(500);
  }
}

/** Wait for loading indicators to finish */
export async function waitForLoading(
  page: Page,
  timeout = 10_000,
): Promise<void> {
  const startTime = Date.now();
  while (Date.now() - startTime < timeout) {
    const hasSpinner = await page.evaluate(() => {
      return document.querySelectorAll('[role="progressbar"]').length > 0;
    });
    if (!hasSpinner) return;
    await page.waitForTimeout(500);
  }
}
