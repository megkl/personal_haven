/**
 * Reads and trims a required string from a callable request payload.
 * Returns null when the field is absent, empty, or not a string.
 * @param {object|null|undefined} source Request payload.
 * @param {string} name Field name.
 * @return {?string} Normalized value.
 */
function requiredString(source, name) {
  if (!source || typeof source !== "object") return null;
  const value = source[name];
  if (typeof value !== "string" || value.trim() === "") return null;
  return value.trim();
}

module.exports = {requiredString};
