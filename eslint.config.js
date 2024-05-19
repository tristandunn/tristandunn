const js = require("@eslint/js"),
      stylistic = require("@stylistic/eslint-plugin-js");

module.exports = [
  {
    "files": ["**/*.js"],
    "ignores": [
      "node_modules/**",
      "vendor/**"
    ],
    "languageOptions": {
      "globals": {
        "module": "readonly",
        "require": "readonly"
      },
      "parserOptions": {
        "sourceType": "module"
      }
    },
    "plugins": {
      "@stylistic/js": stylistic
    },
    "rules": {
      ...js.configs.recommended.rules,
      ...stylistic.configs["all-flat"].rules,

      "@stylistic/js/array-element-newline": ["error", "consistent"],
      "@stylistic/js/function-call-argument-newline": ["error", "consistent"],
      "@stylistic/js/function-paren-newline": ["error", "consistent"],
      "@stylistic/js/indent": [
        "error",
        2, /* eslint no-magic-numbers: 0 */
        {
          "VariableDeclarator": {
            "const": 3,
            "let": 2,
            "var": 2
          }
        }
      ],
      "@stylistic/js/lines-around-comment": ["error", { "allowClassStart": true }],
      "@stylistic/js/object-curly-spacing": ["error", "always"],
      "@stylistic/js/padded-blocks": "off",
      "@stylistic/js/space-before-function-paren": "off",

      "arrow-body-style": ["error", "always"]
    }
  }
];
