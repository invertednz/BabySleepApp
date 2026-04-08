import { test, expect } from "@playwright/test";
import {
  waitForFlutterReady,
  tapFlutterButton,
  getPageText,
} from "../helpers/flutter-helpers";
import { loginAsTestUser } from "../helpers/auth-helpers";

test.describe("Authentication - Welcome Screen Login Link", () => {
  test("should show login link on welcome screen", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    const text = await getPageText(page);
    expect(text).toContain("Already have an account");
  });

  test("should navigate to login screen when tapping log in link", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await tapFlutterButton(page, "Log in");
    await page.waitForTimeout(2000);
    const text = await getPageText(page);
    expect(text).toContain("Welcome Back");
    expect(text).toContain("Log In with Email");
  });

  test("should show email and password fields on login screen", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await tapFlutterButton(page, "Log in");
    await page.waitForTimeout(2000);

    const inputs = page.locator("input");
    const inputCount = await inputs.count();
    expect(inputCount).toBeGreaterThanOrEqual(2);
  });
});

test.describe("Authentication - Login Flow", () => {
  test("should log in and reach the authenticated app", async ({ page }) => {
    test.setTimeout(60_000);
    await loginAsTestUser(page);

    const text = await getPageText(page);
    // Should NOT show onboarding
    expect(text).not.toContain("Congratulations");
    // Should show baby name and app content
    expect(text).toContain("TestBaby");
    expect(text).toContain("STREAK");
  });
});
