/* Mullvad Easier profile (simplified browsing) */

/* Enable userChrome.css */
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

/* Dark theme */
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);

/* Disable letterboxing */
user_pref("privacy.resistFingerprinting.letterboxing", false);

/* Enable history */
user_pref("places.history.enabled", true);
user_pref("browser.privatebrowsing.autostart", false);

/* Session restore settings */
user_pref("browser.sessionstore.interval", 600000);

/* Memory/cache reduction (pairs with Auto Tab Discard) */
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", false);
user_pref("network.prefetch-next", false);
user_pref("browser.sessionhistory.max_total_viewers", 0);
user_pref("browser.sessionstore.max_tabs_undo", 5);
