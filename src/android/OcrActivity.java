package at.ventocom.liveocr;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Menu;
import android.view.View;

import edu.sfsu.cs.orange.ocr.CaptureActivity;
import edu.sfsu.cs.orange.ocr.OcrCharacterHelper;
import edu.sfsu.cs.orange.ocr.PreferencesActivity;

public class OcrActivity extends CaptureActivity {

    public final static String EXTRA_PIN = "pin";
    private final static String TAG = OcrActivity.class.getSimpleName();

    @Override
    public void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        CONTINUOUS_DISPLAY_METADATA = false;
        CONTINUOUS_DISPLAY_RECOGNIZED_TEXT = false;
        DEFAULT_DISABLE_CONTINUOUS_FOCUS = false;
        DISPLAY_SHUTTER_BUTTON = false;
        MUTE_ALL_DIALOGES = true;
    }

    @Override
    protected boolean isEnforcedDefaultPreferences() {
        return true;
    }

    @Override
    protected void setDefaultPreferences() {
        super.setDefaultPreferences();
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);

        // we only detect 0-9 and *. * because there is a row of *'s in the line BEFORE and AFTER our number on the
        // paper. if we ignore *, it will often be detected as 3 or 0. so we need to detect *.
        prefs.edit().putString(OcrCharacterHelper.KEY_CHARACTER_WHITELIST_PORTUGUESE, "0123456789*:/.-").apply();
        prefs.edit().putString(PreferencesActivity.KEY_SOURCE_LANGUAGE_PREFERENCE, "por").apply();
        prefs.edit().putBoolean(PreferencesActivity.KEY_CONTINUOUS_PREVIEW, true).apply();
    }

    @Override
    protected void detectedTextContinously(String text) {
        text = text.replace("\n", "X");
        String numbers = text.replaceAll(" ", "");
        String numberPart;
        if (numbers.length() >= 16) {
            // if the number detected is larger than 16, there might be wrong detections before or after our number. so
            // we need to look at all 16-length substrings of the detection.
            for (int i = 16; i < numbers.length() + 1; i++) {
                numberPart = numbers.substring(i - 16, i);
                // skip all substrings which are not numbers only
                if (!numberPart.matches("\\d+")) continue;
                // the checkums matches, these 16 digits are the winner!
                if (luhnTest(numberPart)) {
                    Intent intent = new Intent();
                    intent.putExtra(EXTRA_PIN, numberPart);
                    // return the digits to the calling activity, which will receive it and put it into the form field.
                    setResult(1, intent);
                    finish();
                    return;
                } else {
                    Log.v(TAG, "luhn test failed!");
                }
            }
        } else {
            Log.v(TAG, "number too short");
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        return false;
    }

    @Override
    protected boolean checkFirstLaunch() {
        return true;
    }

    public boolean luhnTest(String numberPart) {
        int sum = 0;
        boolean alternate = false;
        for (int i = numberPart.length() - 1; i >= 0; i--) {
            int n = Integer.parseInt(numberPart.substring(i, i + 1));
            if (alternate) {
                n *= 2;
                if (n > 9) {
                    n = (n % 10) + 1;
                }
            }
            sum += n;
            alternate = !alternate;
        }
        return (sum % 10 == 0);
    }

    @SuppressWarnings("unused")
    public void abort(View view) {
        Intent intent = new Intent();
        intent.putExtra(EXTRA_PIN, "abort");
        setResult(1, intent);
        finish();
    }
}