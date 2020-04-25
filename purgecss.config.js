module.exports = {
  content : ["./_site/**/*.html"],
  css     : ["./_site/css/application.css"],

  defaultExtractor : (content) => {
    return content.match(/[A-Za-z0-9-_:/]+/g) || [];
  }
};
