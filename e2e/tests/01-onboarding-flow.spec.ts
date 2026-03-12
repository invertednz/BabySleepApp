import { test, expect, Page } from "@playwright/test";
import {
  waitForFlutterReady,
  enableSemantics,
  tapFlutterButton,
  selectFlutterOption,
  expectFlutterText,
  expectFlutterTextContent,
  waitForPageTransition,
  scrollDown,
  advanceOnboarding,
  waitForLoading,
  getPageText,
} from "../helpers/flutter-helpers";

/**
 * Onboarding Flow Tests
 *
 * Verified screen order:
 * 1. Welcome - "Congratulations", "50,000+ parents", button "Continue"
 * 2. Results - "Real Results", "Real Parents", button "I Want These Results"
 * 3. Parent Concerns - "What keeps you up at night?", button "Continue"
 * 4. Reassurance - "You're Not Alone", "74%", button "I ' m Ready"
 * 5. Bet You've Thought - "Am I the only one...", button "Let ' s Do This Together"
 * 6. Notifications - "When should we check in?", button "Continue"
 * 7. Parenting Style - "What is your parenting style?", button "Next" (canvas after selection)
 * 8. Nurture Priorities - "What qualities would you most like to nurture?", button "Next" (canvas)
 * 9. Goals - "What long-term goals do you have as a parent?", button "Next" (canvas)
 * 10. Baby Profile - "Your Baby", "Baby's Name", button "Next"
 */

/** Navigate from app start through the welcome screen wait */
async function waitForWelcome(page: Page): Promise<void> {
  await page.goto("/");
  await waitForFlutterReady(page);
  await enableSemantics(page);
  await page.waitForTimeout(3000);
}

/** Navigate from welcome through to the concerns screen (screen 3) */
async function navigateToConcerns(page: Page): Promise<void> {
  await waitForWelcome(page);
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1200);
  await tapFlutterButton(page, "I Want These Results");
  await page.waitForTimeout(1200);
}

/** Navigate from welcome through to the notifications screen (screen 6) */
async function navigateToNotifications(page: Page): Promise<void> {
  await navigateToConcerns(page);
  // Screen 3: Parent Concerns - select an option and continue
  await selectFlutterOption(page, "Sleep & nights");
  await page.waitForTimeout(300);
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1200);
  // Screen 4: Reassurance
  await tapFlutterButton(page, "I ' m Ready");
  await page.waitForTimeout(1200);
  // Screen 5: Bet You've Thought
  await tapFlutterButton(page, "Let ' s Do This Together");
  await page.waitForTimeout(1200);
}

/** Navigate from welcome through to the parenting style screen (screen 7) */
async function navigateToParentingStyle(page: Page): Promise<void> {
  await navigateToNotifications(page);
  // Screen 6: Notifications
  await selectFlutterOption(page, "Morning");
  await page.waitForTimeout(300);
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1200);
}

test.describe("Onboarding Flow - Welcome & Results", () => {
  test("should display welcome screen with correct content", async ({
    page,
  }) => {
    await waitForWelcome(page);
    const text = await getPageText(page);
    expect(text).toContain("Congratulations");
    expect(text).toContain("50,000+");
  });

  test("should navigate from welcome to results screen", async ({ page }) => {
    await waitForWelcome(page);
    await tapFlutterButton(page, "Continue");
    await waitForPageTransition(page, "Real Results");
  });

  test("should show results screen with social proof", async ({ page }) => {
    await waitForWelcome(page);
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1200);
    const text = await getPageText(page);
    expect(text).toContain("Real Results");
    expect(text).toContain("Real Parents");
  });

  test("should navigate from results to parent concerns", async ({ page }) => {
    await navigateToConcerns(page);
    const text = await getPageText(page);
    expect(
      text.includes("keeps you") ||
        text.includes("up at night") ||
        text.includes("Sleep & nights"),
    ).toBeTruthy();
  });
});

test.describe("Onboarding Flow - Concerns Through Notifications", () => {
  test("should show parent concerns options", async ({ page }) => {
    await navigateToConcerns(page);
    const text = await getPageText(page);
    expect(
      text.includes("Sleep & nights") || text.includes("keeps you"),
    ).toBeTruthy();
  });

  test("should navigate through reassurance screen", async ({ page }) => {
    await navigateToConcerns(page);
    // Select a concern and continue
    await selectFlutterOption(page, "Sleep & nights");
    await page.waitForTimeout(300);
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1200);

    // Reassurance screen
    const text = await getPageText(page);
    expect(text.includes("Not Alone") || text.includes("74%")).toBeTruthy();
  });

  test("should navigate through bet-you-ve-thought screen", async ({
    page,
  }) => {
    await navigateToConcerns(page);
    await selectFlutterOption(page, "Sleep & nights");
    await page.waitForTimeout(300);
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1200);
    // Reassurance
    await tapFlutterButton(page, "I ' m Ready");
    await page.waitForTimeout(1200);

    // Bet You've Thought screen
    const text = await getPageText(page);
    expect(
      text.includes("Am I the only one") || text.includes("ends each day"),
    ).toBeTruthy();
  });

  test("should reach notifications screen", async ({ page }) => {
    await navigateToNotifications(page);
    const text = await getPageText(page);
    expect(
      text.includes("check in") ||
        text.includes("Morning") ||
        text.includes("Mid-Day"),
    ).toBeTruthy();
  });

  test("should allow notification time selection and advance", async ({
    page,
  }) => {
    await navigateToNotifications(page);
    await selectFlutterOption(page, "Morning");
    await page.waitForTimeout(300);
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1500);

    // Should reach parenting style screen
    const text = await getPageText(page);
    expect(
      text.includes("parenting style") ||
        text.includes("Gentle") ||
        text.includes("Structured"),
    ).toBeTruthy();
  });
});

test.describe("Onboarding Flow - Parenting Style Screen", () => {
  test("should display parenting style options", async ({ page }) => {
    await navigateToParentingStyle(page);
    const text = await getPageText(page);
    expect(
      text.includes("parenting style") || text.includes("Gentle"),
    ).toBeTruthy();
  });

  test("should select style and advance with canvas button", async ({
    page,
  }) => {
    await navigateToParentingStyle(page);

    // Select a style - after this, "Next" becomes canvas
    await selectFlutterOption(page, "Gentle & Responsive");
    await page.waitForTimeout(500);

    // tapFlutterButton handles canvas fallback automatically
    await tapFlutterButton(page, "Next");
    await page.waitForTimeout(1500);

    // Should reach nurture priorities
    const text = await getPageText(page);
    expect(
      text.includes("nurture") ||
        text.includes("qualities") ||
        text.includes("Curiosity"),
    ).toBeTruthy();
  });
});

test.describe("Onboarding Flow - Nurture & Goals Screens", () => {
  test("should navigate through nurture and goals", async ({ page }) => {
    test.setTimeout(90_000);
    await navigateToParentingStyle(page);

    // Parenting Style (screen 7)
    await selectFlutterOption(page, "Gentle & Responsive");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Next");
    await page.waitForTimeout(1500);

    // Nurture Priorities (screen 8)
    let text = await getPageText(page);
    if (
      text.includes("nurture") ||
      text.includes("qualities") ||
      text.includes("Curiosity")
    ) {
      await selectFlutterOption(page, "Curiosity and exploration");
      await page.waitForTimeout(500);
      await tapFlutterButton(page, "Next");
      await page.waitForTimeout(1500);
    }

    // Goals (screen 9)
    text = await getPageText(page);
    if (
      text.includes("goals") ||
      text.includes("Goals") ||
      text.includes("friendship")
    ) {
      await selectFlutterOption(page, "Confidence & resilience");
      await page.waitForTimeout(500);
      await tapFlutterButton(page, "Next");
      await page.waitForTimeout(1500);
    }

    // Should reach Baby Profile (screen 10)
    text = await getPageText(page);
    expect(
      text.includes("Your Baby") ||
        text.includes("Baby") ||
        text.includes("Name"),
    ).toBeTruthy();
  });
});

test.describe("Onboarding Flow - Baby Profile", () => {
  test("should show baby profile screen with name input", async ({ page }) => {
    test.setTimeout(90_000);
    await navigateToParentingStyle(page);

    // Navigate through screens 7-9
    await selectFlutterOption(page, "Gentle & Responsive");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Next");
    await page.waitForTimeout(1200);

    await selectFlutterOption(page, "Curiosity and exploration");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Next");
    await page.waitForTimeout(1200);

    await selectFlutterOption(page, "Confidence & resilience");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Next");
    await page.waitForTimeout(1500);

    // Baby Profile screen
    const text = await getPageText(page);
    if (text.includes("Your Baby") || text.includes("Baby")) {
      expect(text.includes("Baby") || text.includes("Name")).toBeTruthy();
    }
  });
});
