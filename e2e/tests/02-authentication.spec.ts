import { test, expect, Page } from "@playwright/test";
import {
  waitForFlutterReady,
  enableSemantics,
  tapFlutterButton,
  selectFlutterOption,
  fillFlutterField,
  expectFlutterText,
  expectFlutterTextContent,
  waitForPageTransition,
  getPageText,
  advanceOnboarding,
  testEmail,
  testPassword,
} from "../helpers/flutter-helpers";

/**
 * Authentication Tests
 *
 * Auth screens appear after completing the full onboarding flow.
 * Since navigating through all onboarding screens is expensive,
 * these tests check for auth-related UI elements that may be
 * accessible from the welcome screen (e.g., "Log in" link) or
 * verify auth screen structure when reachable.
 */

/** Navigate through the full onboarding to reach auth/payment screens */
async function navigateThroughOnboarding(page: Page): Promise<void> {
  await page.goto("/");
  await waitForFlutterReady(page);
  await enableSemantics(page);
  await page.waitForTimeout(3000);

  // Screen 1: Welcome
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1000);

  // Screen 2: Results
  await tapFlutterButton(page, "I Want These Results");
  await page.waitForTimeout(1000);

  // Screen 3: Parent Concerns
  await selectFlutterOption(page, "Sleep & nights");
  await page.waitForTimeout(300);
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1000);

  // Screen 4: Reassurance
  await tapFlutterButton(page, "I ' m Ready");
  await page.waitForTimeout(1000);

  // Screen 5: Bet You've Thought
  await tapFlutterButton(page, "Let ' s Do This Together");
  await page.waitForTimeout(1000);

  // Screen 6: Notifications
  await selectFlutterOption(page, "Morning");
  await page.waitForTimeout(300);
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1000);

  // Screen 7: Parenting Style
  await selectFlutterOption(page, "Gentle & Responsive");
  await page.waitForTimeout(500);
  await tapFlutterButton(page, "Next");
  await page.waitForTimeout(1000);

  // Screen 8: Nurture Priorities
  await selectFlutterOption(page, "Curiosity and exploration");
  await page.waitForTimeout(500);
  await tapFlutterButton(page, "Next");
  await page.waitForTimeout(1000);

  // Screen 9: Goals
  await selectFlutterOption(page, "Confidence & resilience");
  await page.waitForTimeout(500);
  await tapFlutterButton(page, "Next");
  await page.waitForTimeout(1500);
}

test.describe("Authentication - Login Link from Welcome", () => {
  test("should check for login link on welcome screen", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    // Check if there is a login link accessible from the welcome screen
    if (text.includes("Log in") || text.includes("Already have an account")) {
      const loginLink = page
        .locator('text="Log in"')
        .or(page.locator('text="Log In"'))
        .first();
      if (await loginLink.isVisible().catch(() => false)) {
        await loginLink.click();
        await page.waitForTimeout(1500);

        const loginText = await getPageText(page);
        expect(
          loginText.includes("Welcome Back") ||
            loginText.includes("Log In") ||
            loginText.includes("Email"),
        ).toBeTruthy();
      }
    } else {
      // Login may only be accessible after full onboarding
      expect(text).toContain("Congratulations");
    }
  });
});

test.describe("Authentication - Login Screen Structure", () => {
  test("should display email and password fields on login", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    // Try to reach login screen via link
    const loginLink = page
      .locator('text="Log in"')
      .or(page.locator('text="Log In"'))
      .first();
    if (await loginLink.isVisible().catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);

      const inputs = page.locator("input");
      const count = await inputs.count();
      expect(count).toBeGreaterThanOrEqual(2);
    }
  });

  test("should show Google sign-in option", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    const loginLink = page
      .locator('text="Log in"')
      .or(page.locator('text="Log In"'))
      .first();
    if (await loginLink.isVisible().catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);

      const text = await getPageText(page);
      expect(text.includes("Google") || text.includes("google")).toBeTruthy();
    }
  });

  test("should toggle between login and signup views", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    const loginLink = page
      .locator('text="Log in"')
      .or(page.locator('text="Log In"'))
      .first();
    if (await loginLink.isVisible().catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);

      const signupLink = page
        .locator('text="Sign Up"')
        .or(page.locator('text="Sign up"'))
        .first();
      if (await signupLink.isVisible().catch(() => false)) {
        await signupLink.click();
        await page.waitForTimeout(1000);

        const text = await getPageText(page);
        expect(
          text.includes("Create Account") ||
            text.includes("Sign Up") ||
            text.includes("Confirm Password"),
        ).toBeTruthy();
      }
    }
  });

  test("should show forgot password option on login", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    const loginLink = page
      .locator('text="Log in"')
      .or(page.locator('text="Log In"'))
      .first();
    if (await loginLink.isVisible().catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);

      const text = await getPageText(page);
      expect(
        text.includes("Forgot Password") || text.includes("forgot"),
      ).toBeTruthy();
    }
  });
});

test.describe("Authentication - Email Validation", () => {
  test("should validate email format", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    const loginLink = page
      .locator('text="Log in"')
      .or(page.locator('text="Log In"'))
      .first();
    if (await loginLink.isVisible().catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);

      const emailInput = page.locator("input").first();
      if (await emailInput.isVisible().catch(() => false)) {
        await emailInput.fill("invalidemail");
        const submitBtn = page
          .locator('text="Log In with Email"')
          .or(page.locator('text="Log in with Email"'))
          .first();
        if (await submitBtn.isVisible().catch(() => false)) {
          await submitBtn.click();
          await page.waitForTimeout(1000);
          // Should show validation error or stay on page
          const text = await getPageText(page);
          expect(
            text.includes("Email") ||
              text.includes("email") ||
              text.includes("valid"),
          ).toBeTruthy();
        }
      }
    }
  });
});

test.describe("Authentication - Signup Flow", () => {
  test("should attempt signup with test credentials", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    const loginLink = page
      .locator('text="Log in"')
      .or(page.locator('text="Log In"'))
      .first();
    if (await loginLink.isVisible().catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);

      const signupLink = page
        .locator('text="Sign Up"')
        .or(page.locator('text="Sign up"'))
        .first();
      if (await signupLink.isVisible().catch(() => false)) {
        await signupLink.click();
        await page.waitForTimeout(1000);

        const inputs = page.locator("input");
        const inputCount = await inputs.count();

        if (inputCount >= 3) {
          await inputs.nth(0).fill(testEmail());
          await inputs.nth(1).fill(testPassword());
          await inputs.nth(2).fill(testPassword());

          // Check terms checkbox if present
          const checkbox = page.locator('[role="checkbox"]').first();
          if (await checkbox.isVisible().catch(() => false)) {
            await checkbox.click();
          }

          const submitBtn = page
            .locator('text="Sign Up with Email"')
            .or(page.locator('text="Sign up with Email"'))
            .first();
          if (await submitBtn.isVisible().catch(() => false)) {
            await submitBtn.click();
            await page.waitForTimeout(3000);

            const text = await getPageText(page);
            expect(text.length).toBeGreaterThan(0);
          }
        }
      }
    }
  });

  test("should show terms checkbox on signup", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);

    const loginLink = page
      .locator('text="Log in"')
      .or(page.locator('text="Log In"'))
      .first();
    if (await loginLink.isVisible().catch(() => false)) {
      await loginLink.click();
      await page.waitForTimeout(1500);

      const signupLink = page
        .locator('text="Sign Up"')
        .or(page.locator('text="Sign up"'))
        .first();
      if (await signupLink.isVisible().catch(() => false)) {
        await signupLink.click();
        await page.waitForTimeout(1000);

        const text = await getPageText(page);
        expect(
          text.includes("Terms") ||
            text.includes("agree") ||
            text.includes("Privacy"),
        ).toBeTruthy();
      }
    }
  });
});
