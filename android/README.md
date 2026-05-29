# Burrito Bot Android

Native Android client for the Burrito Bot FastAPI backend.

## Open in Android Studio

1. Open the `android` folder in Android Studio.
2. Let Android Studio install the Android Gradle Plugin, Gradle, and SDK components if prompted.
3. Run the `app` configuration on an emulator or device.

## Backend URL

The app calls the backend configured in:

`app/build.gradle`

```groovy
buildConfigField "String", "BURRITO_BOT_BASE_URL", "\"https://burrito-bot.com\""
```

For a backend running on your host machine while using the Android emulator, change it to:

```groovy
buildConfigField "String", "BURRITO_BOT_BASE_URL", "\"http://10.0.2.2:8000\""
```

The Android client posts to `/chat` and expects the existing response shape:

```json
{
  "answer": "...",
  "citations": []
}
```
