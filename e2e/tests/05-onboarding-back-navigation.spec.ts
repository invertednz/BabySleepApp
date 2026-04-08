import { test, expect } from "@playwright/test";
import {
  waitForFlutterReady,
  tapFlutterButton,
  selectFlutterOption,
  getPageText,
  waitForPageTransition,
} from "../helpers/flutter-helpers";

/**
 * Onboarding Back Navigation Tests
 *
 * Tests navigating backwards through onboarding screens using
 * Flutter's in-app back button (arrow icon at top-left).
 * Note: page.goBack() doesn't work reliably with Flutter SPA routing.
 */

/** Click the Flutter in-app back button (arrow icon at top-left corner) */
async function tapBackButton(
  page: import("@playwright/test").Page,
): Promise<void> {
  // Find the back button via semantics — it's the first button near the top-left
  const found = await page.evaluate(() => {
    const buttons = document.querySelectorAll("flt-semantics[role='button']");
    for (const btn of Array.from(buttons)) {
      const rect = (btn as HTMLElement).getBoundingClientRect();
      // Back button is small (< 60px) and at top-left (x < 100, y < 80)
      if (
        rect.width < 60 &&
        rect.height < 60 &&
        rect.x < 100 &&
        rect.y < 80 &&
        rect.width > 0
      ) {
        return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
      }
    }
    return null;
  });

  if (found) {
    await page.mouse.click(found.x, found.y);
    await page.waitForTimeout(1500);
    return;
  }

  // Fallback: click at top-left where back arrow typically is (65, 53 from screenshot)
  await page.mouse.click(65, 53);
  await page.waitForTimeout(1500);
}

test.describe("Onboarding Back Navigation", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
  });

  test("should navigate back from reassurance to concerns", async ({
    page,
  }) => {
    test.setTimeout(90_000);

    // Welcome → Results → Concerns → Reassurance
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Results");
    await tapFlutterButton(page, "I Want These Results");
    await waitForPageTransition(page, "keeps you");
    await selectFlutterOption(page, "Sleep");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Not Alone");

    // Verify we're on Reassurance screen
    const reassuranceText = await getPageText(page);
    expect(reassuranceText).toContain("Not Alone");

    // Go back using in-app back button
    await tapBackButton(page);

    const afterBack = await getPageText(page);
    // Should return to Concerns screen
    expect(afterBack).toContain("keeps you");
  });

  test("should navigate forward again after going back", async ({ page }) => {
    test.setTimeout(90_000);

    // Welcome → Results → Concerns
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Results");
    await tapFlutterButton(page, "I Want These Results");
    await waitForPageTransition(page, "keeps you");

    // Select concern and go to Reassurance
    await selectFlutterOption(page, "Sleep");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Not Alone");

    // Go back to Concerns
    await tapBackButton(page);
    const backText = await getPageText(page);
    expect(backText).toContain("keeps you");

    // Go forward again — select and continue
    await selectFlutterOption(page, "Development");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1500);

    // Should be back on Reassurance with new concern
    const forwardText = await getPageText(page);
    expect(forwardText).toContain("Not Alone");
    expect(forwardText).toContain("Development");
  });
});
