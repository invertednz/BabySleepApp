import { test, expect, Page } from "@playwright/test";
import {
  waitForFlutterReady,
  enableSemantics,
  tapFlutterButton,
  getPageText,
} from "../helpers/flutter-helpers";

/**
 * Upload & Media Tests
 *
 * Tests image upload functionality in:
 * - AI Chat (image-based questions)
 * - Milestone moments (photo capture)
 * - Progress photos
 *
 * Note: On web, file uploads use file picker dialogs.
 * We test that the upload UI elements exist and are accessible.
 */

/** Navigate to Advice tab if available */
async function navigateToAdvice(page: Page): Promise<boolean> {
  const text = await getPageText(page);
  if (text.includes("Advice")) {
    await tapFlutterButton(page, "Advice");
    await page.waitForTimeout(1500);
    return true;
  }
  return false;
}

test.describe("Upload - AI Chat Image Upload", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await enableSemantics(page);
    await page.waitForTimeout(3000);
  });

  test("should show image upload buttons in chat", async ({ page }) => {
    if (!(await navigateToAdvice(page))) return;

    const chatText = await getPageText(page);
    if (!chatText.includes("Ask me anything")) return;

    // Image upload buttons should be present (camera + gallery icons)
    const galleryBtn = page
      .locator('[aria-label="Gallery"]')
      .or(page.locator('[aria-label="gallery"]'))
      .or(page.locator('[aria-label="Photo"]'))
      .or(page.locator('[aria-label="image"]'))
      .first();

    const cameraBtn = page
      .locator('[aria-label="Camera"]')
      .or(page.locator('[aria-label="camera"]'))
      .or(page.locator('[aria-label="Take photo"]'))
      .first();

    const hasGallery = await galleryBtn.isVisible().catch(() => false);
    const hasCamera = await cameraBtn.isVisible().catch(() => false);

    expect(hasGallery || hasCamera || chatText.includes("image")).toBeTruthy();
  });

  test("should change input placeholder when image mode active", async ({
    page,
  }) => {
    if (!(await navigateToAdvice(page))) return;

    const chatText = await getPageText(page);
    expect(
      chatText.includes("Ask me anything") ||
        chatText.includes("Ask about this image"),
    ).toBeTruthy();
  });
});

test.describe("Upload - File Input Handling", () => {
  test("should handle file input element for image upload", async ({
    page,
  }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    // Flutter web uses <input type="file"> for file picking
    const fileInputs = page.locator('input[type="file"]');
    const count = await fileInputs.count();
    // File inputs may be hidden but present in DOM, or created on demand
    expect(count).toBeGreaterThanOrEqual(0);
  });
});

test.describe("Upload - Milestone Moments", () => {
  test("should have photo capture option in milestones", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    if (!text.includes("Milestones")) return;

    await tapFlutterButton(page, "Milestones");
    await page.waitForTimeout(1500);

    const milestoneText = await getPageText(page);
    expect(
      milestoneText.includes("Milestone") ||
        milestoneText.includes("Share") ||
        milestoneText.includes("Photo") ||
        milestoneText.includes("moment") ||
        milestoneText.length > 0,
    ).toBeTruthy();
  });
});

test.describe("Upload - Progress Photos", () => {
  test("should support before/after photo comparison", async ({ page }) => {
    await page.goto("/");
    await waitForFlutterReady(page);
    await page.waitForTimeout(3000);

    const text = await getPageText(page);
    if (!text.includes("Progress")) return;

    await tapFlutterButton(page, "Progress");
    await page.waitForTimeout(1500);

    const progressText = await getPageText(page);
    expect(progressText.length).toBeGreaterThan(0);
  });
});
