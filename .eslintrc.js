module.exports = {
  "env": {
    "browser": true,
    "es2021": true,
    "node": true
  },
  "extends": ["eslint:all"],
  "globals": {
    "document": true,
    "fetch": true,
    "window": true
  },
  "parserOptions": {
    "sourceType": "module"
  },
  "rules": {
    "arrow-body-style": [
      "error",
      "always"
    ],
    "indent": [
      "error",
      2 /* eslint no-magic-numbers: 0 */
    ],
    "object-curly-spacing": [
      "error",
      "always"
    ],
    "padded-blocks": [
      "error",
      "never"
    ]
  }
};
