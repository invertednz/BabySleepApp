import { Page, expect } from "@playwright/test";
import {
  waitForFlutterReady,
  tapFlutterButton,
  getPageText,
} from "./flutter-helpers";

/**
 * Authentication helpers for E2E tests.
 *
 * Logs in via the Flutter UI since the Supabase Flutter SDK
 * stores sessions in IndexedDB (Hive), not localStorage.
 */

// E2E test user credentials
export const TEST_EMAIL = "e2e-test@babysteps-app.com";
export const TEST_PASSWORD = "TestPass123!";

/**
 * Log in as the E2E test user via the app's login UI.
 *
 * This navigates through: Welcome → Login → Fill credentials → Submit.
 * After login, waits for the app to load authenticated content.
 *
 * Usage:
 * ```
 * await loginAsTestUser(page);
 * // page is now on the authenticated home screen
 * ```
 */
export async function loginAsTestUser(page: Page): Promise<void> {
  await page.goto("/");
  await waitForFlutterReady(page);

  // Click "Already have an account? Log in" on welcome screen
  await tapFlutterButton(page, "Log in");
  await page.waitForTimeout(2000);

  // Wait for login screen to fully render with input fields
  const inputs = page.locator("input");
  await inputs.first().waitFor({ state: "visible", timeout: 10_000 });
  await page.waitForTimeout(1000);

  // Fill email — click, clear, then type character by character for reliability
  const emailInput = inputs.nth(0);
  await emailInput.click();
  await emailInput.fill("");
  await emailInput.type(TEST_EMAIL, { delay: 20 });
  await page.waitForTimeout(300);

  // Fill password — same approach
  const passInput = inputs.nth(1);
  await passInput.click();
  await passInput.fill("");
  await passInput.type(TEST_PASSWORD, { delay: 20 });
  await page.waitForTimeout(500);

  // Submit via "Log In with Email" button
  await tapFlutterButton(page, "Log In with Email");

  // Wait for login to complete and app to load
  // The splash screen does several data fetches before routing
  // Poll until we see authenticated content (max 15 seconds)
  const startTime = Date.now();
  while (Date.now() - startTime < 15_000) {
    const text = await getPageText(page);
    if (
      text.includes("TestBaby") ||
      text.includes("STREAK") ||
      text.includes("Progress")
    ) {
      return; // Successfully logged in
    }
    await page.waitForTimeout(1000);
  }

  // Final check
  const finalText = await getPageText(page);
  expect(
    finalText,
    "Login failed — did not reach authenticated app",
  ).not.toContain("Congratulations");
  expect(finalText, "Login failed — still on login screen").not.toContain(
    "Welcome Back",
  );
}

/**
 * Check if the page is showing authenticated app content.
 */
export async function isAuthenticated(page: Page): Promise<boolean> {
  const text = await getPageText(page);
  return (
    !text.includes("Congratulations") &&
    !text.includes("Welcome Back") &&
    (text.includes("TestBaby") ||
      text.includes("Progress") ||
      text.includes("Milestones") ||
      text.includes("Advice") ||
      text.includes("Streak"))
  );
}
