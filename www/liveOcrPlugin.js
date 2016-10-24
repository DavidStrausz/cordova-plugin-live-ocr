var LiveOcrPlugin = {
    recognizeText: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "LiveOcrPlugin", "recognizeText", []);
    },

    loadLanguage: function (language, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "LiveOcrPlugin", "loadLanguage", [language]);
    }
};
module.exports = LiveOcrPlugin;
