/* Mullvad WebApps profile (minimal app-like UI) */

/* Enable userChrome.css */
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

/* Dark theme */
user_pref("ui.systemUsesDarkTheme", 1);

/* Do NOT auto-start in private browsing */
user_pref("browser.privatebrowsing.autostart", false);

/* Disable letterboxing for webapp mode */
user_pref("privacy.resistFingerprinting.letterboxing", false);
user_pref("privacy.resistFingerprinting.letterboxing.warning", false);

/* Nice-to-haves for app-like behavior */
user_pref("browser.tabs.closeWindowWithLastTab", true);
user_pref("browser.fullscreen.autohide", true);

/* Never restore the previous session's tabs in this profile */
user_pref("browser.startup.page", 0);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.sessionstore.resume_session_once", false);
user_pref("browser.sessionstore.max_resumed_crashes", 0);

/* Memory/cache reduction (pairs with Auto Tab Discard) */
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", false);
user_pref("network.prefetch-next", false);
user_pref("browser.sessionhistory.max_total_viewers", 0);
user_pref("browser.sessionstore.max_tabs_undo", 5);
