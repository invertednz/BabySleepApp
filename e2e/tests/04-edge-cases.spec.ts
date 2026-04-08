import { test, expect } from "@playwright/test";
import {
  waitForFlutterReady,
  tapFlutterButton,
  getPageText,
  waitForPageTransition,
} from "../helpers/flutter-helpers";

/**
 * Edge Cases & Error Handling Tests
 *
 * Tests unusual scenarios that work without authentication:
 * page reload, viewport changes, load time.
 */

test.describe("Edge Cases - Page Reload", () => {
  test("should handle page reload during onboarding", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Verify we start on welcome
    const beforeReload = await getPageText(page);
    expect(beforeReload).toContain("Congratulations");

    // Navigate forward
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Results");

    // Reload the page
    await page.reload();
    await waitForFlutterReady(page);

    // App should recover and show a valid screen (welcome or results)
    const afterReload = await getPageText(page);
    expect(
      afterReload.includes("Congratulations") ||
        afterReload.includes("Results"),
    ).toBeTruthy();
  });
});

test.describe("Edge Cases - Viewport Handling", () => {
  test("should render correctly on mobile viewport (390x844)", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    await waitForFlutterReady(page);

    const text = await getPageText(page);
    expect(text).toContain("Congratulations");
    expect(text).toContain("Continue");
  });

  test("should handle viewport resize from mobile to tablet", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    await waitForFlutterReady(page);

    const mobileText = await getPageText(page);
    expect(mobileText).toContain("Congratulations");

    // Resize to tablet
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.waitForTimeout(1500);

    const tabletText = await getPageText(page);
    expect(tabletText).toContain("Congratulations");
  });
});

test.describe("Edge Cases - Performance", () => {
  test("should load within reasonable time (< 10 seconds)", async ({
    page,
  }) => {
    const startTime = Date.now();

    await page.goto("/");
    await waitForFlutterReady(page);

    const loadTime = Date.now() - startTime;
    expect(loadTime).toBeLessThan(10_000);

    const text = await getPageText(page);
    expect(text).toContain("Congratulations");
  });
});
