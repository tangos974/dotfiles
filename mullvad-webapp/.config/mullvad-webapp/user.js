user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

/* Use dark appearance */
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 2);

/* Do NOT auto-start in private browsing for this profile */
user_pref("browser.privatebrowsing.autostart", false);

/* Disable the maximize warning */
user_pref("privacy.resistFingerprinting.letterboxing.warning", false);

/* Nice-to-haves for app-like behavior */
user_pref("browser.tabs.closeWindowWithLastTab", true);
user_pref("browser.sessionstore.resume_session_once", true);
user_pref("browser.fullscreen.autohide", true);
