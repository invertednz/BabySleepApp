import { test, expect } from "@playwright/test";
import {
  waitForFlutterReady,
  tapFlutterButton,
  selectFlutterOption,
  getPageText,
  waitForPageTransition,
  fillFlutterField,
} from "../helpers/flutter-helpers";

/**
 * Full End-to-End Onboarding Flow
 *
 * One long test that walks through the entire onboarding flow
 * as far as possible without authentication:
 *
 * 1. Welcome ("Congratulations") -> "Continue"
 * 2. Results ("Real Results") -> "I Want These Results"
 * 3. Parent Concerns ("What keeps you up at night?") -> select + "Continue"
 * 4. Reassurance ("You're Not Alone") -> "I'm Ready"
 * 5. Feelings ("Bet You've Thought") -> "Let's Do This Together"
 * 6. Notifications ("When should we check in?") -> select + "Continue"
 * 7. Parenting Style -> select + "Next"
 * 8. Nurture Priorities -> select + "Next"
 * 9. Goals -> select + "Next"
 * 10. Baby Profile -> fill name, date, etc.
 */

test.describe("Full E2E - Complete Onboarding Happy Path", () => {
  test("should complete the entire onboarding flow through baby profile", async ({
    page,
  }) => {
    test.setTimeout(120_000);

    await page.goto("/");
    await waitForFlutterReady(page);

    // --- Screen 1: Welcome ---
    let text = await getPageText(page);
    expect(text).toContain("Congratulations");
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1500);

    // --- Screen 2: Results ---
    text = await getPageText(page);
    expect(text).toContain("Results");
    await tapFlutterButton(page, "I Want These Results");
    await page.waitForTimeout(1500);

    // --- Screen 3: Parent Concerns ---
    text = await getPageText(page);
    expect(text).toContain("keeps you");
    await selectFlutterOption(page, "Sleep & nights");
    await page.waitForTimeout(300);
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1500);

    // --- Screen 4: Reassurance ---
    text = await getPageText(page);
    expect(text).toContain("Not Alone");
    await tapFlutterButton(page, "Ready");
    await page.waitForTimeout(1500);

    // --- Screen 5: Feelings / Bet You've Thought ---
    text = await getPageText(page);
    expect(
      text.includes("Am I the only one") || text.includes("ends each day"),
    ).toBeTruthy();
    await tapFlutterButton(page, "Together");
    await page.waitForTimeout(1500);

    // --- Screen 6: Notifications ---
    text = await getPageText(page);
    expect(text).toContain("Morning");
    await selectFlutterOption(page, "Morning");
    await page.waitForTimeout(300);
    await tapFlutterButton(page, "Continue");
    await page.waitForTimeout(1500);

    // --- Screen 7: Parenting Style ---
    text = await getPageText(page);
    expect(text).toContain("Gentle");
    await selectFlutterOption(page, "Gentle & Responsive");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Next");
    await page.waitForTimeout(1500);

    // --- Screen 8: Nurture Priorities ---
    text = await getPageText(page);
    expect(text).toContain("Curiosity");
    await selectFlutterOption(page, "Curiosity and exploration");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Next");
    await page.waitForTimeout(1500);

    // --- Screen 9: Goals ---
    text = await getPageText(page);
    expect(text).toContain("Confidence");
    await selectFlutterOption(page, "Confidence & resilience");
    await page.waitForTimeout(500);
    await tapFlutterButton(page, "Next");
    await page.waitForTimeout(1500);

    // --- Screen 10: Baby Profile ---
    text = await getPageText(page);
    expect(
      text.includes("Baby") || text.includes("Name") || text.includes("baby"),
    ).toBeTruthy();

    // Fill baby name if input is available
    const nameInput = page.locator("input").first();
    if (await nameInput.isVisible().catch(() => false)) {
      await nameInput.fill("Emma");
    }

    // Try to choose date if available
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

    // Try to add baby
    const addBtn = page.locator('text="Add Baby"').first();
    if (await addBtn.isVisible().catch(() => false)) {
      await addBtn.click();
      await page.waitForTimeout(800);
    }

    // Verify we reached the baby profile screen successfully
    const finalText = await getPageText(page);
    expect(
      finalText.includes("Baby") ||
        finalText.includes("Emma") ||
        finalText.includes("Next") ||
        finalText.includes("Gender"),
    ).toBeTruthy();
  });
});
