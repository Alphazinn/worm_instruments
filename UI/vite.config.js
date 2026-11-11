import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// base "./" is mandatory so the built asset URLs resolve from nui://.../UI/dist/ (CODESTYLE 3.19).
// outDir "dist" matches ui_page "UI/dist/index.html" in fxmanifest.lua.
export default defineConfig({
    plugins: [react()],
    base: "./",
    css: {
        preprocessorOptions: {
            scss: {
                // Sass's modern API: the legacy one prints a deprecation warning per stylesheet on every
                // build, and a build whose output nobody reads hides real warnings (worm_restaurant's measurement).
                api: "modern",
            },
        },
    },
    build: {
        outDir: "dist",
    },
});
