import { test, expect } from "@playwright/test";
import {
  waitForFlutterReady,
  tapFlutterButton,
  selectFlutterOption,
  getPageText,
  waitForPageTransition,
} from "../helpers/flutter-helpers";

test.describe("Onboarding Flow - Welcome Through Concerns", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
  });

  test("should display welcome screen with correct content", async ({
    page,
  }) => {
    const text = await getPageText(page);
    expect(text).toContain("Congratulations");
    expect(text).toContain("first step toward becoming the parent");
    expect(text).toContain("Trusted by 50,000+ parents");
    expect(text).toContain("Harvard, Stanford");
    expect(text).toContain("Continue");
    expect(text).toContain("Already have an account");
  });

  test("should navigate welcome → results → concerns → reassurance → feelings", async ({
    page,
  }) => {
    // Welcome → Results
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Real Results");
    const resultsText = await getPageText(page);
    expect(resultsText).toContain("Real Results");
    expect(resultsText).toContain("Real Parents");
    expect(resultsText).toContain("3x");
    expect(resultsText).toContain("milestone achievement");
    expect(resultsText).toContain("87%");
    expect(resultsText).toContain("sleep improvement");
    expect(resultsText).toContain("I Want These Results");

    // Results → Concerns
    await tapFlutterButton(page, "I Want These Results");
    await waitForPageTransition(page, "keeps you up at night");
    const concernsText = await getPageText(page);
    expect(concernsText).toContain("keeps you up at night");
    expect(concernsText).toContain("Sleep");
    expect(concernsText).toContain("Development");
    expect(concernsText).toContain("Feeling confident");

    // Select a concern
    await selectFlutterOption(page, "Sleep");
    await page.waitForTimeout(500);

    // Concerns → Reassurance
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Not Alone");
    const reassuranceText = await getPageText(page);
    expect(reassuranceText).toContain("Not Alone");
    expect(reassuranceText).toContain("3 in 4 parents");
    expect(reassuranceText).toContain("Sleep");
    expect(reassuranceText).toContain("already taken the first step");
    expect(reassuranceText).toContain("turn these into a plan");

    // Reassurance → Feelings
    await tapFlutterButton(page, "Ready");
    await waitForPageTransition(page, "Bet You");
    const feelingsText = await getPageText(page);
    expect(feelingsText).toContain("Bet You");
    expect(feelingsText).toContain("Thought This");
    expect(feelingsText).toContain("wondering if I did enough");
    expect(feelingsText).toContain("9 out of 10 parents");
  });

  test("should navigate feelings → notifications → parenting style", async ({
    page,
  }) => {
    // Fast-forward to feelings screen
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Real Results");
    await tapFlutterButton(page, "I Want These Results");
    await waitForPageTransition(page, "keeps you up at night");
    await selectFlutterOption(page, "Sleep");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Not Alone");
    await tapFlutterButton(page, "Ready");
    await waitForPageTransition(page, "Bet You");

    // Feelings → Notifications
    await tapFlutterButton(page, "Together");
    await waitForPageTransition(page, "check in");
    const notifText = await getPageText(page);
    expect(notifText).toContain("check in");
    expect(notifText).toContain("Morning");
    expect(notifText).toContain("Mid-Day");
    expect(notifText).toContain("Evening");

    // Select a time
    await selectFlutterOption(page, "Morning");
    await page.waitForTimeout(500);

    // Notifications → Parenting Style
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "parenting style");
    const styleText = await getPageText(page);
    expect(styleText).toContain("parenting style");
    expect(styleText).toContain("Gentle");
    expect(styleText).toContain("Structured");
    expect(styleText).toContain("Flexible");
    expect(styleText).toContain("Attachment");
  });
});

test.describe("Onboarding Flow - Concern Selection Variations", () => {
  test("should show different reassurance text for Development concern", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);

    // Navigate to concerns
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Real Results");
    await tapFlutterButton(page, "I Want These Results");
    await waitForPageTransition(page, "keeps you up at night");

    // Select Development concern
    await selectFlutterOption(page, "Development");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Not Alone");

    const text = await getPageText(page);
    expect(text).toContain("Not Alone");
    expect(text).toContain("Development");
  });
});
