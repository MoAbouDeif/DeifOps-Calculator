const { defineConfig } = require("cypress");
const webpackConfig = require("./cypress/webpack.config");

module.exports = defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || "http://192.168.129.111",
    supportFile: false,
  },
  component: {
    devServer: {
      framework: "react",
      bundler: "webpack",
      webpackConfig,
    },
  },
});
