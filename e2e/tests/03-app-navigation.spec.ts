import { test, expect } from "@playwright/test";
import {
  waitForFlutterReady,
  tapFlutterButton,
  selectFlutterOption,
  getPageText,
  waitForPageTransition,
  scrollDown,
  isTextVisible,
  findInAccessibilityTree,
  tapAccessibilityNode,
} from "../helpers/flutter-helpers";
import { loginAsTestUser } from "../helpers/auth-helpers";

/**
 * App Navigation Tests (Authenticated)
 *
 * Tests tab navigation and screen content after login.
 * Each test logs in via UI, which takes ~10s.
 */

test.describe("App Navigation - Home Screen", () => {
  test("should show home screen with baby name and streak after login", async ({
    page,
  }) => {
    test.setTimeout(60_000);
    await loginAsTestUser(page);

    const text = await getPageText(page);
    expect(text).toContain("TestBaby");
    expect(text).toContain("STREAK");
  });

  test("should show milestone summary cards on home screen", async ({
    page,
  }) => {
    test.setTimeout(60_000);
    await loginAsTestUser(page);

    const text = await getPageText(page);
    // Home screen has UPCOMING and DELAYED milestone counters
    expect(text).toContain("UPCOMING");
    expect(text).toContain("milestones");
  });
});

test.describe("App Navigation - Recommendations (Advice Section)", () => {
  test("should show recommendation cards after scrolling", async ({ page }) => {
    test.setTimeout(60_000);
    await loginAsTestUser(page);

    // Scroll to recommendations
    await scrollDown(page, 400);
    await scrollDown(page, 400);
    await scrollDown(page, 400);

    // Use Chrome's CDP Accessibility Tree — it has full text even after scroll
    const recsHeader = await findInAccessibilityTree(page, "Recommendations");
    expect(
      recsHeader,
      "Recommendations section should exist in accessibility tree",
    ).not.toBeNull();

    const bedtimeCard = await findInAccessibilityTree(page, "Bedtime Routine");
    expect(
      bedtimeCard,
      "Bedtime Routine card should exist in accessibility tree",
    ).not.toBeNull();
  });

  test("should expand recommendation when tapped and show Read full article", async ({
    page,
  }) => {
    test.setTimeout(60_000);

    // Use a very tall viewport so recommendations are visible WITHOUT scrolling.
    // This avoids the CanvasKit scroll vs DOM position mismatch.
    await page.setViewportSize({ width: 390, height: 3000 });
    await loginAsTestUser(page);
    await page.waitForTimeout(2000);

    // Verify "Bedtime Routine" is in the accessibility tree
    const card = await findInAccessibilityTree(page, "Bedtime Routine");
    expect(card, "Bedtime Routine card should exist").not.toBeNull();

    // Verify "Read full article" is NOT in the tree before expanding
    const beforeExpand = await findInAccessibilityTree(
      page,
      "Read full article",
    );
    expect(
      beforeExpand,
      "Read full article should NOT exist before expanding",
    ).toBeNull();

    // Click the card to expand it via CDP coordinates (no scroll needed = coords match)
    await tapAccessibilityNode(page, "Bedtime Routine");
    await page.waitForTimeout(1500);

    // After expanding, "Read full article" should appear
    const afterExpand = await findInAccessibilityTree(
      page,
      "Read full article",
    );
    expect(
      afterExpand,
      "Read full article should appear after expanding",
    ).not.toBeNull();
  });

  test("should collapse recommendation when tapped again", async ({ page }) => {
    test.setTimeout(60_000);

    // Tall viewport to avoid scrolling
    await page.setViewportSize({ width: 390, height: 3000 });
    await loginAsTestUser(page);
    await page.waitForTimeout(2000);

    // Expand
    await tapAccessibilityNode(page, "Bedtime Routine");
    await page.waitForTimeout(1500);
    const expanded = await findInAccessibilityTree(page, "Read full article");
    expect(expanded, "Should be expanded").not.toBeNull();

    // Collapse
    await tapAccessibilityNode(page, "Bedtime Routine");
    await page.waitForTimeout(1500);
    const collapsed = await findInAccessibilityTree(page, "Read full article");
    expect(
      collapsed,
      "Read full article should disappear after collapsing",
    ).toBeNull();
  });
});

test.describe("App Navigation - Tab Navigation", () => {
  test("should navigate to Milestones tab", async ({ page }) => {
    test.setTimeout(60_000);
    await loginAsTestUser(page);

    // The home screen should have a bottom nav. Click Milestones.
    await tapFlutterButton(page, "Milestones");
    await page.waitForTimeout(2000);

    const text = await getPageText(page);
    expect(text).toContain("Milestones");
    // Should show milestone groups
    expect(text.includes("Months") || text.includes("Years")).toBeTruthy();
  });

  test("should navigate to Progress tab", async ({ page }) => {
    test.setTimeout(60_000);
    await loginAsTestUser(page);

    await tapFlutterButton(page, "Progress");
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    expect(text).toContain("TestBaby");
    // Progress screen shows domain scores or percentiles
    expect(
      text.includes("Progress") ||
        text.includes("percentile") ||
        text.includes("N/A") ||
        text.includes("Overall"),
    ).toBeTruthy();
  });
});
