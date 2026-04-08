import { test, expect } from "@playwright/test";
import {
  waitForFlutterReady,
  tapFlutterButton,
  selectFlutterOption,
  getPageText,
} from "../helpers/flutter-helpers";

test("smoke test - basic onboarding navigation", async ({ page }) => {
  await page.goto("/");
  await waitForFlutterReady(page);

  // Screen 1: Welcome
  const text1 = await getPageText(page);
  expect(text1).toContain("Congratulations");
  expect(text1).toContain("Continue");

  // Screen 2: Results
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1500);
  const text2 = await getPageText(page);
  expect(text2).toContain("Real Results");

  // Screen 3: Concerns
  await tapFlutterButton(page, "I Want These Results");
  await page.waitForTimeout(1500);
  const text3 = await getPageText(page);
  expect(text3).toContain("keeps you up at night");

  // Screen 4: Reassurance
  await selectFlutterOption(page, "Sleep");
  await page.waitForTimeout(400);
  await tapFlutterButton(page, "Continue");
  await page.waitForTimeout(1500);
  const text4 = await getPageText(page);
  expect(text4).toContain("Not Alone");

  // Screen 5: Bet You've Thought
  await tapFlutterButton(page, "Ready");
  await page.waitForTimeout(1500);
  const text5 = await getPageText(page);
  expect(text5).toContain("Bet You");
});
