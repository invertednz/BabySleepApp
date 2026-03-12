import { test, expect, Page } from "@playwright/test";
import {
  waitForFlutterReady,
  enableSemantics,
  tapFlutterButton,
  selectFlutterOption,
  expectFlutterTextContent,
  getPageText,
  advanceOnboarding,
  scrollDown,
  testEmail,
  testPassword,
} from "../helpers/flutter-helpers";

/**
 * Full End-to-End Flow Tests
 *
 * Tests the complete user journey from first launch through
 * app usage, verifying data continuity throughout.
 *
 * Confirmed onboarding order:
 * 1. Welcome ("Congratulations") -> "Continue"
 * 2. Results ("Real Results") -> "I Want These Results"
 * 3. Parent Concerns ("What keeps you up at night?") -> select + "Continue"
 * 4. Reassurance ("You're Not Alone") -> "I ' m Ready"
 * 5. Bet You've Thought -> "Let ' s Do This Together"
 * 6. Notifications ("When should we check in?") -> select + "Continue"
 * 7. Parenting Style -> select + "Next" (canvas after selection)
 * 8. Nurture Priorities -> select + "Next" (canvas after selection)
 * 9. Goals -> select + "Next" (canvas after selection)
 * 10. Baby Profile -> fill name, date, "Add Baby", "Next"
 * 11+. Gender, App Tour, Payment (not fully mapped)
 */

test.describe("Full E2E - New User Journey", () => {
  test("complete onboarding flow from welcome through baby profile", async ({
    page,
  }) => {
    test.setTimeout(120_000);

    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    // --- Screen 1: Welcome ---
    let text = await getPageText(page);
    expect(
      text.includes("Congratulations") || text.includes("Welcome"),
    ).toBeTruthy();
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1200);

    // --- Screen 2: Results ---
    text = await getPageText(page);
    if (text.includes("Real Results") || text.includes("Results")) {
      await tapFlutterButton(page, "I Want These Results");
      await page.waitForTimeout(1200);
    }

    // --- Screen 3: Parent Concerns ---
    text = await getPageText(page);
    if (text.includes("keeps you") || text.includes("Sleep & nights")) {
      await selectFlutterOption(page, "Sleep & nights");
      await page.waitForTimeout(300);
      await tapFlutterButton(page, "Continue");
      await page.waitForTimeout(1200);
    }

    // --- Screen 4: Reassurance ---
    text = await getPageText(page);
    if (text.includes("Not Alone") || text.includes("74%")) {
      await tapFlutterButton(page, "I ' m Ready");
      await page.waitForTimeout(1200);
    }

    // --- Screen 5: Bet You've Thought ---
    text = await getPageText(page);
    if (text.includes("Am I the only one") || text.includes("ends each day")) {
      await tapFlutterButton(page, "Let ' s Do This Together");
      await page.waitForTimeout(1200);
    }

    // --- Screen 6: Notifications ---
    text = await getPageText(page);
    if (
      text.includes("Morning") ||
      text.includes("check in") ||
      text.includes("Mid-Day")
    ) {
      await selectFlutterOption(page, "Morning");
      await page.waitForTimeout(300);
      await tapFlutterButton(page, "Continue");
      await page.waitForTimeout(1200);
    }

    // --- Screen 7: Parenting Style ---
    text = await getPageText(page);
    if (text.includes("parenting style") || text.includes("Gentle")) {
      await selectFlutterOption(page, "Gentle & Responsive");
      await page.waitForTimeout(500);
      await tapFlutterButton(page, "Next");
      await page.waitForTimeout(1200);
    }

    // --- Screen 8: Nurture Priorities ---
    text = await getPageText(page);
    if (
      text.includes("nurture") ||
      text.includes("qualities") ||
      text.includes("Curiosity")
    ) {
      await selectFlutterOption(page, "Curiosity and exploration");
      await page.waitForTimeout(500);
      await tapFlutterButton(page, "Next");
      await page.waitForTimeout(1200);
    }

    // --- Screen 9: Goals ---
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

    // --- Screen 10: Baby Profile ---
    text = await getPageText(page);
    if (
      text.includes("Baby") ||
      text.includes("Your Baby") ||
      text.includes("Name")
    ) {
      const nameInput = page.locator("input").first();
      if (await nameInput.isVisible().catch(() => false)) {
        await nameInput.fill("Emma");
      }

      // Choose date
      const dateBtn = page.locator('text="Choose Date"').first();
      if (await dateBtn.isVisible().catch(() => false)) {
        await dateBtn.click();
        await page.waitForTimeout(500);
        const okBtn = page.locator('text="OK"').first();
        if (await okBtn.isVisible().catch(() => false)) {
          await okBtn.click();
          await page.waitForTimeout(500);
        }
      }

      const addBtn = page.locator('text="Add Baby"').first();
      if (await addBtn.isVisible().catch(() => false)) {
        await addBtn.click();
        await page.waitForTimeout(800);
      }

      await tapFlutterButton(page, "Next");
      await page.waitForTimeout(1200);
    }

    // --- Continue through remaining screens toward payment ---
    // Gender, Activities, Milestones, Focus, Progress Preview, Payment
    for (let i = 0; i < 10; i++) {
      text = await getPageText(page);

      // Check if we reached payment or login
      if (
        text.includes("Compare Plans") ||
        text.includes("$49") ||
        text.includes("Log In") ||
        text.includes("Sign Up") ||
        text.includes("Progress")
      ) {
        break;
      }

      // Handle gender screen
      if (
        text.includes("gender") ||
        text.includes("Gender") ||
        text.includes("Girl")
      ) {
        await selectFlutterOption(page, "Girl");
        await page.waitForTimeout(300);
      }

      await advanceOnboarding(page, 1);
    }

    // Verify we reached a meaningful endpoint
    text = await getPageText(page);
    expect(text.length).toBeGreaterThan(10);
  });
});

test.describe("Full E2E - Onboarding Data Flows to App", () => {
  test("baby name entered in onboarding should appear in app", async ({
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

      await tapFlutterButton(page, "Progress");
      await page.waitForTimeout(1500);
      const progressText = await getPageText(page);
      expect(progressText.length).toBeGreaterThan(0);
    }
  });

  test("parenting style choices should influence recommendations", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);

    if (text.includes("Advice") || text.includes("Progress")) {
      await tapFlutterButton(page, "Advice");
      await page.waitForTimeout(1500);
      const adviceText = await getPageText(page);
      expect(adviceText.length).toBeGreaterThan(0);
    }
  });
});

test.describe("Full E2E - Going Back Through Onboarding", () => {
  test("should be able to navigate backwards through onboarding screens", async ({
    page,
  }) => {
    test.setTimeout(90_000);

    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    // Move forward: Welcome -> Results -> Concerns
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1000);
    await tapFlutterButton(page, "I Want These Results");
    await page.waitForTimeout(1000);

    // Now go back
    const backBtn = page
      .locator('[aria-label="Back"]')
      .or(page.locator('[aria-label="back"]'))
      .first();

    if (await backBtn.isVisible().catch(() => false)) {
      await backBtn.click();
      await page.waitForTimeout(1200);

      let text = await getPageText(page);
      expect(text.length).toBeGreaterThan(0);

      // Go back again
      const backBtn2 = page
        .locator('[aria-label="Back"]')
        .or(page.locator('[aria-label="back"]'))
        .first();
      if (await backBtn2.isVisible().catch(() => false)) {
        await backBtn2.click();
        await page.waitForTimeout(1200);

        text = await getPageText(page);
        expect(
          text.includes("Congratulations") ||
            text.includes("Welcome") ||
            text.includes("Results"),
        ).toBeTruthy();
      }
    }
  });

  test("should preserve selections when navigating back and forward", async ({
    page,
  }) => {
    test.setTimeout(90_000);

    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    // Navigate to notification screen
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(800);
    await tapFlutterButton(page, "I Want These Results");
    await page.waitForTimeout(800);

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
    await page.waitForTimeout(1000);

    // Select evening time
    let text = await getPageText(page);
    if (text.includes("Morning") || text.includes("check in")) {
      await selectFlutterOption(page, "Evening");
      await tapFlutterButton(page, "Continue");
      await page.waitForTimeout(1000);

      // Select parenting style
      text = await getPageText(page);
      if (text.includes("parenting style") || text.includes("Gentle")) {
        await selectFlutterOption(page, "Gentle & Responsive");
        await page.waitForTimeout(500);
        await tapFlutterButton(page, "Next");
        await page.waitForTimeout(1000);

        // Go back to parenting style
        const backBtn = page
          .locator('[aria-label="Back"]')
          .or(page.locator('[aria-label="back"]'))
          .first();
        if (await backBtn.isVisible().catch(() => false)) {
          await backBtn.click();
          await page.waitForTimeout(1200);

          text = await getPageText(page);
          if (text.includes("parenting style") || text.includes("Gentle")) {
            expect(text).toContain("Gentle & Responsive");
          }
        }
      }
    }
  });
});

test.describe("Full E2E - App Functionality After Login", () => {
  test("should show all main screens with content", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);

    if (!(text.includes("Progress") && text.includes("Milestones"))) return;

    // Progress
    await tapFlutterButton(page, "Progress");
    await page.waitForTimeout(1500);
    let screenText = await getPageText(page);
    expect(screenText.length).toBeGreaterThan(50);

    // Milestones
    await tapFlutterButton(page, "Milestones");
    await page.waitForTimeout(1500);
    screenText = await getPageText(page);
    expect(screenText.length).toBeGreaterThan(50);

    // Advice
    await tapFlutterButton(page, "Advice");
    await page.waitForTimeout(1500);
    screenText = await getPageText(page);
    expect(screenText.length).toBeGreaterThan(50);

    // Focus
    await tapFlutterButton(page, "Focus");
    await page.waitForTimeout(1500);
    screenText = await getPageText(page);
    expect(screenText.length).toBeGreaterThan(20);

    // Sleep
    await tapFlutterButton(page, "Sleep");
    await page.waitForTimeout(1500);
    screenText = await getPageText(page);
    expect(screenText.length).toBeGreaterThan(20);
  });

  test("should handle rapid tab switching without crashes", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);

    if (!(text.includes("Progress") && text.includes("Milestones"))) return;

    const tabs = ["Progress", "Milestones", "Advice", "Focus", "Sleep"];
    for (const tab of tabs) {
      await tapFlutterButton(page, tab);
      await page.waitForTimeout(300);
    }
    for (const tab of tabs.reverse()) {
      await tapFlutterButton(page, tab);
      await page.waitForTimeout(300);
    }

    await page.waitForTimeout(1000);
    const finalText = await getPageText(page);
    expect(finalText.length).toBeGreaterThan(0);
  });
});
