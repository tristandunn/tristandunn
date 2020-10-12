const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  future : {
    purgeLayersByDefault         : true,
    removeDeprecatedGapUtilities : true // eslint-disable-line id-length
  },

  plugins : [],

  theme : {
    extend : {},

    fontFamily : {
      sans : ["Inter", ...defaultTheme.fontFamily.sans]
    }
  },

  variants : {}
};
