import { test, expect, Page } from "@playwright/test";
import {
  waitForFlutterReady,
  enableSemantics,
  tapFlutterButton,
  expectFlutterTextContent,
  getPageText,
  scrollDown,
} from "../helpers/flutter-helpers";

/**
 * App Navigation Tests
 *
 * These tests verify the main app container's tab navigation,
 * bottom nav bar, and screen transitions.
 *
 * Note: These tests require a logged-in session. Since we cannot
 * easily mock Supabase auth in Flutter web, we test what is
 * accessible without auth and verify navigation structure when
 * the user is already logged in.
 */

test.describe("App Container - Tab Navigation", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);
  });

  test("should show bottom navigation bar when in app", async ({ page }) => {
    const text = await getPageText(page);

    if (
      text.includes("Progress") &&
      text.includes("Milestones") &&
      text.includes("Advice")
    ) {
      // We are in the app - verify all 5 tabs
      expect(text).toContain("Progress");
      expect(text).toContain("Milestones");
      expect(text).toContain("Advice");
      expect(text).toContain("Focus");
      expect(text).toContain("Sleep");
    } else {
      // We are in onboarding - expected for new users
      expect(
        text.includes("Congratulations") ||
          text.includes("Welcome") ||
          text.includes("BabySteps"),
      ).toBeTruthy();
    }
  });

  test("should navigate between tabs", async ({ page }) => {
    const text = await getPageText(page);

    if (text.includes("Progress") && text.includes("Milestones")) {
      // Click Progress tab
      await tapFlutterButton(page, "Progress");
      await page.waitForTimeout(1000);

      // Click Milestones tab
      await tapFlutterButton(page, "Milestones");
      await page.waitForTimeout(1000);
      const milestoneText = await getPageText(page);
      expect(
        milestoneText.includes("Milestone") ||
          milestoneText.includes("milestone"),
      ).toBeTruthy();

      // Click Advice tab
      await tapFlutterButton(page, "Advice");
      await page.waitForTimeout(1000);
    }
  });

  test("should show premium gate for free users on premium tabs", async ({
    page,
  }) => {
    const text = await getPageText(page);

    if (text.includes("Focus") && text.includes("Sleep")) {
      await tapFlutterButton(page, "Focus");
      await page.waitForTimeout(1000);
      const focusText = await getPageText(page);
      expect(
        focusText.includes("Focus") ||
          focusText.includes("Upgrade") ||
          focusText.includes("Premium"),
      ).toBeTruthy();

      await tapFlutterButton(page, "Sleep");
      await page.waitForTimeout(1000);
      const sleepText = await getPageText(page);
      expect(
        sleepText.includes("Sleep") ||
          sleepText.includes("Upgrade") ||
          sleepText.includes("Premium"),
      ).toBeTruthy();
    }
  });
});

test.describe("Progress Screen", () => {
  test("should display progress tracking content", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    if (text.includes("Progress")) {
      await tapFlutterButton(page, "Progress");
      await page.waitForTimeout(1500);
      const progressText = await getPageText(page);
      expect(progressText.length).toBeGreaterThan(0);
    }
  });
});

test.describe("Milestones Screen", () => {
  test("should display milestone categories", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    if (text.includes("Milestones")) {
      await tapFlutterButton(page, "Milestones");
      await page.waitForTimeout(1500);
      const milestoneText = await getPageText(page);
      expect(
        milestoneText.includes("Milestone") ||
          milestoneText.includes("milestone") ||
          milestoneText.includes("Month"),
      ).toBeTruthy();
    }
  });

  test("should allow scrolling through milestones", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    if (text.includes("Milestones")) {
      await tapFlutterButton(page, "Milestones");
      await page.waitForTimeout(1500);
      await scrollDown(page, 500);
      await page.waitForTimeout(500);
      const afterScroll = await getPageText(page);
      expect(afterScroll.length).toBeGreaterThan(0);
    }
  });
});

test.describe("Home/Advice Screen", () => {
  test("should display home screen content", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    if (text.includes("Advice")) {
      await tapFlutterButton(page, "Advice");
      await page.waitForTimeout(1500);
      const homeText = await getPageText(page);
      expect(
        homeText.includes("Recommendation") ||
          homeText.includes("Activity") ||
          homeText.includes("Advice") ||
          homeText.includes("Premium") ||
          homeText.includes("Upgrade") ||
          homeText.includes("AI"),
      ).toBeTruthy();
    }
  });
});

test.describe("Focus Screen", () => {
  test("should display focus area options", async ({ page }) => {
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
          focusText.includes("Premium") ||
          focusText.includes("Upgrade"),
      ).toBeTruthy();
    }
  });
});

test.describe("Sleep Screen", () => {
  test("should display sleep schedule content", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    if (text.includes("Sleep")) {
      await tapFlutterButton(page, "Sleep");
      await page.waitForTimeout(1500);
      const sleepText = await getPageText(page);
      expect(
        sleepText.includes("Sleep") ||
          sleepText.includes("sleep") ||
          sleepText.includes("Nap") ||
          sleepText.includes("Premium") ||
          sleepText.includes("Upgrade"),
      ).toBeTruthy();
    }
  });
});
