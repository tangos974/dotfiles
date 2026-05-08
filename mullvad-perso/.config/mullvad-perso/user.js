/* Mullvad Perso profile (default browsing profile) */

/* Enable userChrome.css */
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

/* Dark theme */
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);

/* Disable letterboxing for regular browsing */
user_pref("privacy.resistFingerprinting.letterboxing", false);

/* Enable history */
user_pref("places.history.enabled", true);
user_pref("browser.privatebrowsing.autostart", false);

/* Session restore settings */
user_pref("browser.sessionstore.interval", 600000);
