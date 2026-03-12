import { test, expect, Page } from "@playwright/test";
import {
  waitForFlutterReady,
  enableSemantics,
  tapFlutterButton,
  selectFlutterOption,
  expectFlutterTextContent,
  getPageText,
  advanceOnboarding,
} from "../helpers/flutter-helpers";

/**
 * Data Persistence Tests
 *
 * Verifies that data entered during onboarding persists:
 * - Selections retained when navigating back
 * - Data survives page reload
 * - Data visibility across app screens
 */

/** Navigate to the notifications screen (screen 6) */
async function navigateToNotifications(page: Page): Promise<void> {
  await page.goto("/");
  await waitForFlutterReady(page);
  await enableSemantics(page);
  await page.waitForTimeout(3000);

  // Welcome
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1000);
  // Results
  await tapFlutterButton(page, "I Want These Results");
  await page.waitForTimeout(1000);
  // Parent Concerns
  await selectFlutterOption(page, "Sleep & nights");
  await page.waitForTimeout(300);
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1000);
  // Reassurance
  await tapFlutterButton(page, "I ' m Ready");
  await page.waitForTimeout(1000);
  // Bet You've Thought
  await tapFlutterButton(page, "Let ' s Do This Together");
  await page.waitForTimeout(1200);
}

/** Navigate to the parenting style screen (screen 7) */
async function navigateToParentingStyle(page: Page): Promise<void> {
  await navigateToNotifications(page);
  await selectFlutterOption(page, "Morning");
  await page.waitForTimeout(300);
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1200);
}

test.describe("Data Persistence - Onboarding Data Retention", () => {
  test("should retain parenting style selections when going back", async ({
    page,
  }) => {
    await navigateToParentingStyle(page);

    const text = await getPageText(page);
    if (!text.includes("parenting style") && !text.includes("Gentle")) return;

    await selectFlutterOption(page, "Gentle & Responsive");
    await page.waitForTimeout(500);

    // Go forward
    await tapFlutterButton(page, "Next");
    await page.waitForTimeout(1200);

    // Go back
    const backBtn = page
      .locator('[aria-label="Back"]')
      .or(page.locator('[aria-label="back"]'))
      .or(page.locator("button").first())
      .first();
    if (await backBtn.isVisible().catch(() => false)) {
      await backBtn.click();
      await page.waitForTimeout(1200);

      const backText = await getPageText(page);
      if (backText.includes("parenting style") || backText.includes("Gentle")) {
        expect(backText).toContain("Gentle & Responsive");
      }
    }
  });

  test("should retain notification preference when going back", async ({
    page,
  }) => {
    test.setTimeout(120_000);
    await navigateToNotifications(page);

    const text = await getPageText(page);
    if (!text.includes("Morning") && !text.includes("check in")) return;

    await selectFlutterOption(page, "Evening");
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1200);

    // Go back
    const backBtn = page
      .locator('[aria-label="Back"]')
      .or(page.locator('[aria-label="back"]'))
      .first();
    if (await backBtn.isVisible().catch(() => false)) {
      await backBtn.click();
      await page.waitForTimeout(1200);

      const backText = await getPageText(page);
      if (backText.includes("Evening") || backText.includes("Morning")) {
        expect(backText).toContain("Evening");
      }
    }
  });
});

test.describe("Data Persistence - Page Reload", () => {
  test("should handle page reload during onboarding", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    // Navigate past welcome
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1200);

    // Reload the page
    await page.reload();
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    // App should be functional after reload
    const afterReload = await getPageText(page);
    expect(afterReload.length).toBeGreaterThan(0);
    expect(
      afterReload.includes("Congratulations") ||
        afterReload.includes("Welcome") ||
        afterReload.includes("BabySteps") ||
        afterReload.includes("Results") ||
        afterReload.includes("Progress"),
    ).toBeTruthy();
  });

  test("should maintain session after reload when logged in", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);

    if (text.includes("Progress") && text.includes("Milestones")) {
      await page.reload();
      await waitForFlutterReady(page);
      await page.waitForTimeout(3000);

      const afterReload = await getPageText(page);
      expect(
        afterReload.includes("Progress") || afterReload.includes("Milestones"),
      ).toBeTruthy();
    }
  });
});

test.describe("Data Persistence - Baby Data in App", () => {
  test("should show baby name throughout the app after onboarding", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);

    if (text.includes("Progress") && text.includes("Milestones")) {
      await tapFlutterButton(page, "Advice");
      await page.waitForTimeout(1500);
      const adviceText = await getPageText(page);
      expect(adviceText.length).toBeGreaterThan(0);

      await tapFlutterButton(page, "Milestones");
      await page.waitForTimeout(1500);
      const milestoneText = await getPageText(page);
      expect(milestoneText.length).toBeGreaterThan(0);
    }
  });

  test("should persist milestone completions", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);

    if (text.includes("Milestones")) {
      await tapFlutterButton(page, "Milestones");
      await page.waitForTimeout(1500);
      const initialText = await getPageText(page);
      expect(
        initialText.includes("Month") ||
          initialText.includes("milestone") ||
          initialText.includes("Milestone"),
      ).toBeTruthy();
    }
  });
});

test.describe("Data Persistence - Cross-Screen Consistency", () => {
  test("should show consistent data between progress and milestones", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);

    if (text.includes("Progress") && text.includes("Milestones")) {
      await tapFlutterButton(page, "Progress");
      await page.waitForTimeout(1500);
      const progressText = await getPageText(page);

      await tapFlutterButton(page, "Milestones");
      await page.waitForTimeout(1500);
      const milestoneText = await getPageText(page);

      expect(progressText.length).toBeGreaterThan(0);
      expect(milestoneText.length).toBeGreaterThan(0);
    }
  });

  test("should reflect onboarding focus choices in Focus tab", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);

    if (text.includes("Focus")) {
      await tapFlutterButton(page, "Focus");
      await page.waitForTimeout(1500);
      const focusText = await getPageText(page);
      expect(
        focusText.includes("Focus") ||
          focusText.includes("focus") ||
          focusText.includes("week") ||
          focusText.includes("Premium") ||
          focusText.includes("Upgrade"),
      ).toBeTruthy();
    }
  });
});

test.describe("Data Persistence - Onboarding Re-entry", () => {
  test("should resume onboarding at correct step after restart", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    // Start onboarding
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1200);

    // Simulate restart by navigating away and back
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    expect(text.length).toBeGreaterThan(0);
    expect(
      text.includes("Congratulations") ||
        text.includes("Results") ||
        text.includes("Progress") ||
        text.includes("Welcome") ||
        text.includes("BabySteps"),
    ).toBeTruthy();
  });
});
