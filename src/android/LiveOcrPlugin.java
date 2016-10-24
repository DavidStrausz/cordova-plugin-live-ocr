package at.ventocom.liveocr;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URL;
import java.util.zip.GZIPInputStream;

public class LiveOcrPlugin extends CordovaPlugin {

    public String result;
    public CallbackContext callbackContext;
    private String DATA_PATH = "";
    private String lang = "por";
    private static final String TAG = "LiveOcrPlugin";
    private static final String CAMERA = Manifest.permission.CAMERA;
    private static final int CAMERA_REQ_CODE = 0;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext cC) throws JSONException {
        callbackContext = cC;

        try {
            if (getStorageDirectory() != null) {
                DATA_PATH = getStorageDirectory().toString();
                Log.v(TAG, "DATA_PATH = " + DATA_PATH);
            } else {
                Log.v(TAG, "getStorageDirectory() returned null");
            }

            if (action.equals("recognizeText")) {
                Boolean loadingReady = loadLanguage("por");
                if (cordova.hasPermission(CAMERA) && loadingReady) {
                    if (startScanner()) {
                        Log.v(TAG, "Successfully started scanner!");
                    } else {
                        echo(null, callbackContext);
                    }
                } else {
                    getCameraPermission(CAMERA_REQ_CODE);
                }
            } else {
                loadLanguage(args.getString(0));
            }

            // DATA_PATH = this.cordova.getActivity().getApplicationContext().getFilesDir().toString() + "/OCRFolder/";
            return true;

        } catch (Exception e) {
            Log.v(TAG, "Exception in execute: " + e.getMessage());
            echo(null, callbackContext);
            return false;
        }
    }

    private void getCameraPermission(int requestCode) {
        int currentapiVersion = android.os.Build.VERSION.SDK_INT;
        if (currentapiVersion >= Build.VERSION_CODES.KITKAT) {
            cordova.requestPermission(this, requestCode, CAMERA);
        } else {
            startScanner();
        }
    }

    public void onRequestPermissionResult(int requestCode, String[] permissions,
                                          int[] grantResults) throws JSONException {
        for (int r : grantResults) {
            if (r == PackageManager.PERMISSION_DENIED) {
                Log.v(TAG, "Camera permission denied!");
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "Bitte Kamerazugriff zulassen"));
                return;
            }
        }

        switch (requestCode) {
            case CAMERA_REQ_CODE:
                if (startScanner()) {
                    break;
                } else {
                    echo(null, callbackContext);
                }
        }
    }

    private File getStorageDirectory() {
        String state = null;
        try {
            state = Environment.getExternalStorageState();
        } catch (RuntimeException e) {
            Log.e(TAG, "Is the SD card visible?", e);
            Log.d("Error", "Required external storage (such as an SD card) is unavailable.");
        }

        if (Environment.MEDIA_MOUNTED.equals(Environment.getExternalStorageState())) {

            try {
                File file =  this.cordova.getActivity().getApplicationContext().getExternalFilesDir(Environment.MEDIA_MOUNTED);
                if (file != null) {
                    return file;
                } else {
                    return this.cordova.getActivity().getApplicationContext().getFilesDir();
                }
            } catch (NullPointerException e) {
                // We get an error here if the SD card is visible, but full
                Log.e(TAG, "External storage is unavailable");
                Log.d("Error", "Required external storage (such as an SD card) is full or unavailable.");
                return this.cordova.getActivity().getApplicationContext().getFilesDir();
            }

        } else if (Environment.MEDIA_MOUNTED_READ_ONLY.equals(state)) {
            // We can only read the media
            Log.e(TAG, "External storage is read-only");
            Log.d("Error", "Required external storage (such as an SD card) is unavailable for data storage, trying to use internal storage!");
            return this.cordova.getActivity().getApplicationContext().getFilesDir();
        } else {
            // Something else is wrong. It may be one of many other states, but all we need
            // to know is we can neither read nor write
            Log.e(TAG, "External storage is unavailable");
            Log.d("Error", "Required external storage (such as an SD card) is unavailable or corrupted, trying to use internal storage!");
            return this.cordova.getActivity().getApplicationContext().getFilesDir();
        }
    }

    private boolean startScanner() {
        try {
            Context context = this.cordova.getActivity().getApplicationContext();
            Intent intent = new Intent(context, OcrActivity.class);
            cordova.startActivityForResult(this, intent, 1);
            return true;
        } catch (Exception e) {
            Log.v(TAG, "Could not start scanner");
            return false;
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (data == null) {
            Log.v(TAG, "OcrActivity returned no data");
            this.echo(null, callbackContext);
        } else {
            result = data.getStringExtra(OcrActivity.EXTRA_PIN);
            Log.v(TAG, result);
            if (result.equals("abort")) {
                this.echo(result, callbackContext);
            } else {
                this.echo(result, callbackContext);
            }
        }
    }

    private void echo(String result, CallbackContext callbackContext) {
        if (result == null) {
            callbackContext.error("abort");
        } else if (result.length() > 0 && !result.equals("abort")) {
            callbackContext.success(result);
        } else if (result.equals("abort")) {
            callbackContext.error("abort");
        } else {
            callbackContext.error("Der Code konnte leider nicht erkannt werden!");
        }
    }

    private boolean loadLanguage(String language) {
        Log.v(TAG, "Starting process to load OCR language file.");
        String[] paths = new String[]{DATA_PATH, DATA_PATH + "/tessdata/"};
        for (String path : paths) {
            File dir = new File(path);
            if (!dir.exists()) {
                if (!dir.mkdirs()) {
                    Log.v(TAG, "Error: Creation of directory " + path + " failed");
                    return false;
                } else {
                    Log.v(TAG, "Directory created " + path);
                }
            }
        }

        if (language != null && !language.equals("")) {
            lang = language;
        }

        if (!(new File(DATA_PATH + "/tessdata/" + lang + ".traineddata")).exists()) {
            DownloadAndCopy job = new DownloadAndCopy();
            job.execute(lang);
        }
        return true;
    }

    private class DownloadAndCopy extends AsyncTask<String, Void, String> {

        @Override
        protected String doInBackground(String[] params) {
            // do above Server call here
            try {
                Log.v(TAG, "Downloading " + lang + ".traineddata");
                URL url = new URL("https://cdn.rawgit.com/naptha/tessdata/gh-pages/3.02/" + lang + ".traineddata.gz");
                GZIPInputStream gzip = new GZIPInputStream(url.openStream());
                Log.v(TAG, "Downloaded and unziped " + lang + ".traineddata");

                OutputStream out = new FileOutputStream(DATA_PATH
                        + "/tessdata/" + lang + ".traineddata");

                byte[] buf = new byte[1024];
                int len;
                while ((len = gzip.read(buf)) > 0) {
                    out.write(buf, 0, len);
                }

                gzip.close();
                out.close();

                Log.v(TAG, "Copied " + lang + ".traineddata");
            } catch (IOException e) {
                Log.e(TAG, "Unable to copy " + lang + ".traineddata " + e.toString());
            }

            return "Copied " + lang + ".traineddata";
        }

        @Override
        protected void onPostExecute(String message) {
            Log.v(TAG, "Download and copy done! Nothing else to do.");
        }
    }
}