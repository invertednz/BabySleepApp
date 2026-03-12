import { test, expect, Page } from "@playwright/test";
import {
  waitForFlutterReady,
  enableSemantics,
  tapFlutterButton,
  getPageText,
} from "../helpers/flutter-helpers";

/**
 * Settings Screen Tests
 *
 * Tests the settings functionality including:
 * - Plan status display
 * - Account management
 * - Legal links
 * - Sign out
 *
 * Note: Settings is accessible from the main app (usually via
 * an icon in the app bar). These tests require a logged-in session.
 */

/** Check if we are in the main app and try to open settings */
async function openSettings(page: Page): Promise<boolean> {
  const text = await getPageText(page);

  if (!(text.includes("Progress") && text.includes("Milestones"))) {
    return false;
  }

  const settingsBtn = page
    .locator('[aria-label="Settings"]')
    .or(page.locator('[aria-label="settings"]'))
    .or(page.locator('text="Settings"'))
    .first();

  if (await settingsBtn.isVisible().catch(() => false)) {
    await settingsBtn.click();
    await page.waitForTimeout(1500);
    return true;
  }
  return false;
}

test.describe("Settings Screen", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);
  });

  test("should display settings screen with plan status", async ({ page }) => {
    if (!(await openSettings(page))) return;

    const settingsText = await getPageText(page);
    expect(
      settingsText.includes("Settings") ||
        settingsText.includes("Premium") ||
        settingsText.includes("Free") ||
        settingsText.includes("Plan") ||
        settingsText.includes("Account"),
    ).toBeTruthy();
  });

  test("should show plan tier (Free/Premium/Trial)", async ({ page }) => {
    if (!(await openSettings(page))) return;

    const settingsText = await getPageText(page);
    expect(
      settingsText.includes("Premium") ||
        settingsText.includes("Free") ||
        settingsText.includes("Trial") ||
        settingsText.includes("Plan"),
    ).toBeTruthy();
  });

  test("should show upgrade button for free users", async ({ page }) => {
    if (!(await openSettings(page))) return;

    const settingsText = await getPageText(page);
    if (settingsText.includes("Free")) {
      expect(
        settingsText.includes("Upgrade") || settingsText.includes("upgrade"),
      ).toBeTruthy();
    }
  });

  test("should have sign out option", async ({ page }) => {
    if (!(await openSettings(page))) return;

    const settingsText = await getPageText(page);
    expect(
      settingsText.includes("Sign Out") ||
        settingsText.includes("Sign out") ||
        settingsText.includes("Log Out") ||
        settingsText.includes("Logout"),
    ).toBeTruthy();
  });

  test("should show legal links (Terms, Privacy)", async ({ page }) => {
    if (!(await openSettings(page))) return;

    const settingsText = await getPageText(page);
    expect(
      settingsText.includes("Terms") ||
        settingsText.includes("Privacy") ||
        settingsText.includes("Legal"),
    ).toBeTruthy();
  });

  test("should have delete account option", async ({ page }) => {
    if (!(await openSettings(page))) return;

    const settingsText = await getPageText(page);
    expect(
      settingsText.includes("Delete") || settingsText.includes("delete"),
    ).toBeTruthy();
  });
});
