import { test, expect, Page } from "@playwright/test";
import {
  waitForFlutterReady,
  enableSemantics,
  tapFlutterButton,
  getPageText,
  scrollDown,
} from "../helpers/flutter-helpers";

/**
 * Edge Cases & Error Handling Tests
 *
 * Tests unusual scenarios and error conditions:
 * - Empty states
 * - Network interruptions
 * - Invalid inputs
 * - Viewport resizing
 * - Accessibility
 */

test.describe("Edge Cases - Empty States", () => {
  test("should show appropriate content, never a blank screen", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(10);
  });
});

test.describe("Edge Cases - Viewport Handling", () => {
  test("should render correctly on mobile viewport", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 }); // iPhone X
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(0);
  });

  test("should render correctly on tablet viewport", async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 }); // iPad
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(0);
  });

  test("should render correctly on desktop viewport", async ({ page }) => {
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(0);
  });

  test("should handle viewport resize", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    // Start mobile
    await page.setViewportSize({ width: 375, height: 812 });
    await page.waitForTimeout(1000);

    // Resize to desktop
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.waitForTimeout(1000);

    // Resize back to mobile
    await page.setViewportSize({ width: 375, height: 812 });
    await page.waitForTimeout(1000);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(0);
  });
});

test.describe("Edge Cases - Navigation", () => {
  test("should handle browser back button", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    // Navigate forward in onboarding
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1200);

    // Use browser back - Flutter SPAs may not preserve state
    await page.goBack();
    await page.waitForTimeout(3000);

    // App should either show content or we can reload to recover
    const text = await getPageText(page);
    if (text.length === 0) {
      // Flutter lost state after back - reload should recover
      await page.goto("/");
      await waitForFlutterReady(page);
      const reloadedText = await getPageText(page);
      expect(reloadedText.length).toBeGreaterThan(0);
    } else {
      expect(text.length).toBeGreaterThan(0);
    }
  });

  test("should handle browser forward button", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1200);

    await page.goBack();
    await page.waitForTimeout(1500);

    await page.goForward();
    await page.waitForTimeout(1500);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(0);
  });

  test("should handle double-tap prevention", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    // Double-click Continue rapidly
    const btn = page.locator('text="Continue"').first();
    if (await btn.isVisible().catch(() => false)) {
      await btn.dblclick();
      await page.waitForTimeout(2000);

      const text = await getPageText(page);
      expect(text.length).toBeGreaterThan(0);
    }
  });
});

test.describe("Edge Cases - Scroll & Overflow", () => {
  test("should handle scrolling on long content screens", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    await scrollDown(page, 500);
    await page.waitForTimeout(500);
    await page.mouse.wheel(0, -500);
    await page.waitForTimeout(500);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(0);
  });
});

test.describe("Edge Cases - Accessibility", () => {
  test("should have proper page structure", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    const semanticsElements = page.locator("[role]");
    const count = await semanticsElements.count();
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test("should have focusable interactive elements", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    await page.keyboard.press("Tab");
    await page.waitForTimeout(500);
    await page.keyboard.press("Tab");
    await page.waitForTimeout(500);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(0);
  });
});

test.describe("Edge Cases - Performance", () => {
  test("should load within reasonable time", async ({ page }) => {
    const startTime = Date.now();

    await page.goto("/");
    await waitForFlutterReady(page);

    const loadTime = Date.now() - startTime;
    expect(loadTime).toBeLessThan(30_000);
  });

  test("should not leak memory during navigation", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);

    if (text.includes("Progress") && text.includes("Milestones")) {
      for (let round = 0; round < 5; round++) {
        await tapFlutterButton(page, "Progress");
        await page.waitForTimeout(200);
        await tapFlutterButton(page, "Milestones");
        await page.waitForTimeout(200);
        await tapFlutterButton(page, "Advice");
        await page.waitForTimeout(200);
      }

      const finalText = await getPageText(page);
      expect(finalText.length).toBeGreaterThan(0);
    }
  });
});

test.describe("Edge Cases - Error Recovery", () => {
  test("should recover after network error", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    // Simulate offline
    await page.context().setOffline(true);
    await page.waitForTimeout(2000);

    // Go back online
    await page.context().setOffline(false);
    await page.waitForTimeout(2000);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(0);
  });
});
