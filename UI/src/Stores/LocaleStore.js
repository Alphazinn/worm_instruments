import { create } from "zustand";

/**
 * Holds the active locale: the UI subset of the Language table, handed over by Lua when a page opens (PLAN
 * section 5). A store rather than a module variable because the strings arrive after the first render, and only a
 * subscription re-renders the surfaces that read them.
 */
export const useLocaleStore = create((Set) => ({
    Strings: {},
    IsLoaded: false,

    /**
     * Installs the locale handed over by Lua.
     * @param {Object<string, string>} Strings - keyed exactly as Locales/*.lua
     */
    Load: (Strings) => Set({ Strings: Strings || {}, IsLoaded: true }),
}));
