-- The active locale, read once: every file reads Language["Key"], and an unknown Config.Locale falls back to En.
Language = Languages[Config.Locale] or Languages["En"]
