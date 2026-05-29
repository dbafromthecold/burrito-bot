# Burrito Bot

Burrito Bot is a FastAPI-backed restaurant recommendation demo using SQL Server vector search and Azure OpenAI.

This branch also includes a native Android client in [`android`](android/).

## Backend

The existing backend remains in the repository root:

- `app.py` serves the FastAPI app and `/chat` endpoint.
- `ui.html` serves the browser UI.
- `requirements.txt` lists the Python dependencies.

## Android App

Open the `android` folder in Android Studio and run the `app` configuration.

The Android app posts to the backend `/chat` endpoint configured in `android/app/build.gradle`.
