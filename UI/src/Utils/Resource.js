/**
 * The resource name as CEF sees it. GetParentResourceName() is injected by FiveM into every NUI frame; the literal
 * fallback only triggers when the UI is opened in a plain browser during development. Resolving it at runtime means
 * renaming the resource folder can never break a fetch or an asset URL (CODESTYLE 3.5).
 */
export const ResourceName =
    typeof GetParentResourceName === "function"
        ? GetParentResourceName()
        : "worm_instruments";
