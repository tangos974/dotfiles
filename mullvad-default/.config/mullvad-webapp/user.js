/* Enable userChrome.css */
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

/* Disable letterboxing for non-WebApps profiles (WebApps keeps default Mullvad letterboxing). */
user_pref("privacy.resistFingerprinting.letterboxing", false);

user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);