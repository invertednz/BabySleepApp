import { defineConfig, devices } from "@playwright/test";

/**
 * Playwright config for BabySteps Flutter Web App
 *
 * Flutter web uses CanvasKit or HTML renderer. With HTML renderer,
 * actual DOM elements are created that Playwright can interact with.
 * With CanvasKit, Flutter creates a semantics overlay with aria labels.
 *
 * We target the semantics tree using role/label selectors.
 */
export default defineConfig({
  testDir: "./tests",
  fullyParallel: false, // Flutter web tests should run sequentially
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [["html"], ["list"]],
  timeout: 60_000, // Flutter web can be slow to load
  expect: {
    timeout: 15_000,
  },
  use: {
    baseURL: process.env.BASE_URL || "http://localhost:9090",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "on-first-retry",
    // Flutter web needs extra time to initialize
    navigationTimeout: 30_000,
    actionTimeout: 15_000,
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 390, height: 844 },
      },
    },
  ],
  // Serve the pre-built Flutter web app using npx serve
  webServer: {
    command: "npx serve ../babysteps_app/build/web -l 9090 --no-clipboard",
    url: "http://localhost:9090",
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
    stdout: "pipe",
    stderr: "pipe",
  },
});
