package com.example.burritobot;

import android.app.Activity;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends Activity {
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private EditText questionInput;
    private EditText resultCountInput;
    private Button searchButton;
    private LinearLayout results;
    private ProgressBar progress;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(buildLayout());
    }

    @Override
    protected void onDestroy() {
        executor.shutdownNow();
        super.onDestroy();
    }

    private View buildLayout() {
        ScrollView scrollView = new ScrollView(this);
        scrollView.setFillViewport(true);
        scrollView.setBackgroundColor(color("111316"));

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(20), dp(20), dp(20), dp(28));
        scrollView.addView(root, matchWrap());

        TextView title = text("Burrito Bot", 30, "F5F7FA", Typeface.BOLD);
        root.addView(title, matchWrap());

        TextView subtitle = text("Ask for Mexican restaurant recommendations and get grounded results from the Burrito Bot backend.", 15, "AAB3BF", Typeface.NORMAL);
        LinearLayout.LayoutParams subtitleParams = matchWrap();
        subtitleParams.setMargins(0, dp(6), 0, dp(20));
        root.addView(subtitle, subtitleParams);

        LinearLayout form = new LinearLayout(this);
        form.setOrientation(LinearLayout.VERTICAL);
        form.setPadding(dp(16), dp(16), dp(16), dp(16));
        form.setBackground(cardBackground("1C2128", "343B45", dp(8)));
        root.addView(form, matchWrap());

        questionInput = new EditText(this);
        questionInput.setSingleLine(false);
        questionInput.setMinLines(2);
        questionInput.setMaxLines(4);
        questionInput.setHint("Where should I get tacos in Dublin?");
        questionInput.setHintTextColor(color("7E8794"));
        questionInput.setTextColor(color("F5F7FA"));
        questionInput.setTextSize(16);
        questionInput.setImeOptions(EditorInfo.IME_ACTION_SEARCH);
        questionInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        questionInput.setBackground(fieldBackground());
        questionInput.setPadding(dp(12), dp(10), dp(12), dp(10));
        form.addView(questionInput, matchWrap());

        LinearLayout controls = new LinearLayout(this);
        controls.setOrientation(LinearLayout.HORIZONTAL);
        controls.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams controlsParams = matchWrap();
        controlsParams.setMargins(0, dp(12), 0, 0);
        form.addView(controls, controlsParams);

        resultCountInput = new EditText(this);
        resultCountInput.setText("5");
        resultCountInput.setSelectAllOnFocus(true);
        resultCountInput.setInputType(InputType.TYPE_CLASS_NUMBER);
        resultCountInput.setTextColor(color("F5F7FA"));
        resultCountInput.setTextSize(16);
        resultCountInput.setGravity(Gravity.CENTER);
        resultCountInput.setBackground(fieldBackground());
        resultCountInput.setPadding(dp(8), 0, dp(8), 0);
        controls.addView(resultCountInput, new LinearLayout.LayoutParams(dp(72), dp(48)));

        searchButton = new Button(this);
        searchButton.setText("Search");
        searchButton.setTextColor(color("FFFFFF"));
        searchButton.setTextSize(15);
        searchButton.setAllCaps(false);
        searchButton.setBackground(cardBackground("2F7D6D", "2F7D6D", dp(8)));
        LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(0, dp(48), 1);
        buttonParams.setMargins(dp(12), 0, 0, 0);
        controls.addView(searchButton, buttonParams);
        searchButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                submitQuestion();
            }
        });

        progress = new ProgressBar(this);
        progress.setVisibility(View.GONE);
        LinearLayout.LayoutParams progressParams = new LinearLayout.LayoutParams(dp(42), dp(42));
        progressParams.gravity = Gravity.CENTER_HORIZONTAL;
        progressParams.setMargins(0, dp(18), 0, dp(4));
        root.addView(progress, progressParams);

        results = new LinearLayout(this);
        results.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams resultsParams = matchWrap();
        resultsParams.setMargins(0, dp(16), 0, 0);
        root.addView(results, resultsParams);

        addEmptyState();
        return scrollView;
    }

    private void submitQuestion() {
        final String question = questionInput.getText().toString().trim();
        if (question.isEmpty()) {
            showError("Please ask a question first.");
            return;
        }

        int topK = parseTopK();
        setLoading(true);

        final JSONObject payload = new JSONObject();
        try {
            payload.put("question", question);
            payload.put("top_k", topK);
        } catch (Exception ex) {
            showError(ex.getMessage());
            setLoading(false);
            return;
        }

        executor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    JSONObject response = postChat(payload);
                    showResponse(response);
                } catch (Exception ex) {
                    showError("Could not reach Burrito Bot: " + ex.getMessage());
                } finally {
                    setLoading(false);
                }
            }
        });
    }

    private JSONObject postChat(JSONObject payload) throws Exception {
        String baseUrl = BuildConfig.BURRITO_BOT_BASE_URL;
        URL url = new URL(baseUrl.replaceAll("/+$", "") + "/chat");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setConnectTimeout(20000);
        conn.setReadTimeout(45000);
        conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
        conn.setRequestProperty("Accept", "application/json");
        conn.setDoOutput(true);

        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(conn.getOutputStream(), StandardCharsets.UTF_8));
        writer.write(payload.toString());
        writer.flush();
        writer.close();

        int status = conn.getResponseCode();
        InputStream stream = status >= 200 && status < 300 ? conn.getInputStream() : conn.getErrorStream();
        String body = readAll(stream);
        conn.disconnect();

        JSONObject json = body.isEmpty() ? new JSONObject() : new JSONObject(body);
        if (status < 200 || status >= 300) {
            throw new IllegalStateException(json.optString("error", "HTTP " + status));
        }
        return json;
    }

    private String readAll(InputStream stream) throws Exception {
        if (stream == null) {
            return "";
        }
        BufferedReader reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8));
        StringBuilder out = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            out.append(line);
        }
        reader.close();
        return out.toString();
    }

    private void showResponse(final JSONObject response) {
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                results.removeAllViews();
                String answer = response.optString("answer", "");
                if (!answer.isEmpty()) {
                    addAnswerCard(answer);
                }

                JSONArray citations = response.optJSONArray("citations");
                if (citations == null || citations.length() == 0) {
                    if (answer.isEmpty()) {
                        addEmptyState();
                    }
                    return;
                }

                for (int i = 0; i < citations.length(); i++) {
                    JSONObject row = citations.optJSONObject(i);
                    if (row != null) {
                        addRestaurantCard(row);
                    }
                }
            }
        });
    }

    private void addAnswerCard(String answer) {
        LinearLayout card = card();
        TextView label = text("Burrito Bot says", 13, "AAB3BF", Typeface.BOLD);
        card.addView(label, matchWrap());

        TextView body = text(answer, 16, "F5F7FA", Typeface.NORMAL);
        LinearLayout.LayoutParams bodyParams = matchWrap();
        bodyParams.setMargins(0, dp(8), 0, 0);
        card.addView(body, bodyParams);
        results.addView(card, spacedCardParams());
    }

    private void addRestaurantCard(JSONObject row) {
        LinearLayout card = card();
        String name = first(row, "name", "Name", "restaurant_name");
        String city = first(row, "city", "City");
        String rating = first(row, "rating", "Rating");
        String address = first(row, "address", "Address");

        card.addView(text(name.isEmpty() ? "Restaurant" : name, 18, "F5F7FA", Typeface.BOLD), matchWrap());

        String summary = joinNonEmpty(city, rating.isEmpty() ? "" : "Rating " + rating);
        if (!summary.isEmpty()) {
            TextView meta = text(summary, 14, "AAB3BF", Typeface.NORMAL);
            LinearLayout.LayoutParams metaParams = matchWrap();
            metaParams.setMargins(0, dp(4), 0, 0);
            card.addView(meta, metaParams);
        }

        if (!address.isEmpty()) {
            TextView addressView = text(address, 14, "F5F7FA", Typeface.NORMAL);
            LinearLayout.LayoutParams addressParams = matchWrap();
            addressParams.setMargins(0, dp(10), 0, 0);
            card.addView(addressView, addressParams);
        }

        Iterator<String> keys = row.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            String lower = key.toLowerCase();
            if (lower.equals("name") || lower.equals("city") || lower.equals("rating") || lower.equals("address")
                    || lower.equals("combined_reviews") || lower.equals("metadata_text")) {
                continue;
            }
            String value = row.optString(key, "");
            if (value.isEmpty() || value.equalsIgnoreCase("n/a")) {
                continue;
            }
            TextView detail = text(key + ": " + value, 13, "AAB3BF", Typeface.NORMAL);
            LinearLayout.LayoutParams detailParams = matchWrap();
            detailParams.setMargins(0, dp(8), 0, 0);
            card.addView(detail, detailParams);
        }

        results.addView(card, spacedCardParams());
    }

    private void addEmptyState() {
        results.removeAllViews();
        LinearLayout card = card();
        card.addView(text("Ready when you are", 17, "F5F7FA", Typeface.BOLD), matchWrap());
        TextView body = text("Try asking for tacos, burritos, margaritas, or a neighborhood recommendation.", 14, "AAB3BF", Typeface.NORMAL);
        LinearLayout.LayoutParams params = matchWrap();
        params.setMargins(0, dp(8), 0, 0);
        card.addView(body, params);
        results.addView(card, spacedCardParams());
    }

    private void showError(final String message) {
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                results.removeAllViews();
                LinearLayout card = card();
                card.setBackground(cardBackground("2A1C1F", "62353B", dp(8)));
                card.addView(text(message, 15, "F59A9A", Typeface.NORMAL), matchWrap());
                results.addView(card, spacedCardParams());
            }
        });
    }

    private void setLoading(final boolean loading) {
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                searchButton.setEnabled(!loading);
                searchButton.setText(loading ? "Searching..." : "Search");
                progress.setVisibility(loading ? View.VISIBLE : View.GONE);
            }
        });
    }

    private int parseTopK() {
        try {
            int value = Integer.parseInt(resultCountInput.getText().toString());
            return Math.max(1, Math.min(50, value));
        } catch (Exception ignored) {
            return 5;
        }
    }

    private LinearLayout card() {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(16), dp(16), dp(16));
        card.setBackground(cardBackground("1C2128", "343B45", dp(8)));
        return card;
    }

    private TextView text(String value, int sp, String hexColor, int style) {
        TextView textView = new TextView(this);
        textView.setText(value);
        textView.setTextColor(color(hexColor));
        textView.setTextSize(sp);
        textView.setLineSpacing(0, 1.12f);
        textView.setTypeface(Typeface.DEFAULT, style);
        return textView;
    }

    private GradientDrawable cardBackground(String fill, String stroke, int radius) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color(fill));
        drawable.setCornerRadius(radius);
        drawable.setStroke(dp(1), color(stroke));
        return drawable;
    }

    private GradientDrawable fieldBackground() {
        return cardBackground("252B33", "3A424D", dp(8));
    }

    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private LinearLayout.LayoutParams spacedCardParams() {
        LinearLayout.LayoutParams params = matchWrap();
        params.setMargins(0, 0, 0, dp(12));
        return params;
    }

    private String first(JSONObject row, String... keys) {
        for (String key : keys) {
            String value = row.optString(key, "");
            if (!value.isEmpty() && !value.equalsIgnoreCase("n/a")) {
                return value;
            }
        }
        return "";
    }

    private String joinNonEmpty(String left, String right) {
        if (left.isEmpty()) {
            return right;
        }
        if (right.isEmpty()) {
            return left;
        }
        return left + " - " + right;
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private int color(String hex) {
        return android.graphics.Color.parseColor("#" + hex);
    }
}
