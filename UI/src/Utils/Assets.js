import { ResourceName } from "./Resource";

/**
 * Resolves an image from the resource-level Assets folder (CODESTYLE 3.5). An absolute cfx-nui URL resolves
 * identically in the Vite build and in production, while relative ../ chains depend on where index.html lands.
 * @param {string} Category - subfolder under Assets/Images ("Renders", "Screens", "Texture")
 * @param {string} FileName - file name including extension
 * @returns {string} absolute cfx-nui image URL
 */
export const GetImage = (Category, FileName) => {
    return `https://cfx-nui-${ResourceName}/Assets/Images/${Category}/${FileName}`;
};

/**
 * Resolves a UI sound from the resource-level Assets folder (UISTYLE 3.6: open, close, confirm, deny, hold, tab).
 * The instruments' notes are the sampler's (Utils/AudioEngine.js); the world's one-shots are native game audio in the
 * assets resource.
 * @param {string} Name - the sound's file name without its extension
 * @returns {HTMLAudioElement}
 */
export const GetSound = (Name) => {
    return new Audio(`https://cfx-nui-${ResourceName}/Assets/SoundEffects/${Name}.wav`);
};

/**
 * Resolves a file of the instruments' sample library (Assets/Sounds): its Manifest.json, or a sample the manifest
 * names by its path inside the library ("Piano/Recorded/60.ogg").
 * @param {string} Path - the file's path inside Assets/Sounds
 * @returns {string} absolute cfx-nui URL
 */
export const GetSample = (Path) => {
    return `https://cfx-nui-${ResourceName}/Assets/Sounds/${Path}`;
};
