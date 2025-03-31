import os
import re
import json
import openai
import faiss
import pandas as pd
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv
from prompt_toolkit import prompt
from prompt_toolkit.styles import Style

# set csv and index files
CSV_FILE = 'processed_burrito_data.csv'
FAISS_INDEX_FILE = 'burrito_index.faiss'

# load variables from .env file
load_dotenv()

# set variables from .env file
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
OPENAI_ORG = os.getenv('OPENAI_ORG')
OPENAI_PROJECT = os.getenv('OPENAI_PROJECT')

# initialize the OpenAI client
client = openai.Client(
    api_key=OPENAI_API_KEY,
    organization=OPENAI_ORG,
    project=OPENAI_PROJECT
)

# load the processed data
if not os.path.exists(CSV_FILE):
    raise FileNotFoundError(f"CSV file '{CSV_FILE}' not found.")
df = pd.read_csv(CSV_FILE)

# load the FAISS index
if not os.path.exists(FAISS_INDEX_FILE):
    raise FileNotFoundError(f"FAISS index file '{FAISS_INDEX_FILE}' not found.")
index = faiss.read_index(FAISS_INDEX_FILE)

# load sentence transformer model
sentence_model = SentenceTransformer('all-MiniLM-L6-v2')

# keep track of shown results across the session
shown_indices = set()
last_min_rating = 0
last_preferences = []
last_location = ""

# chatbot function
def chatbot():
    print("\n🌯 Welcome to the Dublin Burrito Bot!")
    print("❓ Ask me anything about burrito restaurants (e.g., 'I want 3 spicy burrito places with 4+ stars').\n")

    style = Style.from_dict({
        'prompt': 'bold #00FFFF',
        '': 'bold #FFA500'
    })

    global shown_indices, last_min_rating, last_preferences, last_location

    while True:
        user_input = prompt('You: ', style=style)
        print("\n")

        if user_input.lower() in ['exit', 'quit', 'bah']:
            print("👋 Goodbye!\n")
            break

        is_followup = user_input.strip().lower() in ["give me another one", "another one", "show me more", "more"]

        if is_followup:
            num_results = 1
        else:
            # Step 1: Use GPT to extract structured query intent
            analysis_prompt = f"""
You are a helpful assistant for a burrito restaurant search bot.
Your job is to extract user intent and return it as a JSON object.

Only return a JSON object. Do not include explanations or extra text.

The object must include:
- num_results (int): number of restaurants requested (default 3)
- min_rating (float): minimum star rating if specified (default 0)
- keywords (list of strings): any burrito type or feature (like 'spicy', 'vegetarian')
- location (string): area or neighborhood if mentioned, otherwise empty string

User query: "{user_input}"
"""

            try:
                response = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[
                        {"role": "system", "content": "Respond only with valid JSON."},
                        {"role": "user", "content": analysis_prompt}
                    ]
                )
                intent_text = response.choices[0].message.content.strip()
                intent_text = re.sub(r"^```(json)?|```$", "", intent_text).strip()
                intent = json.loads(intent_text)
            except Exception as e:
                print(f"❌ Error understanding your request: {e}")
                continue

            num_results = max(1, min(20, intent.get("num_results", 3)))
            last_min_rating = intent.get("min_rating", 0)
            last_preferences = intent.get("keywords", [])
            last_location = intent.get("location", "")

        # Step 2: Construct search description
        search_desc = "Find burrito places"
        if last_preferences:
            search_desc += " that are " + ", ".join(last_preferences)
        if last_location:
            search_desc += f" in {last_location}"
        if last_min_rating:
            search_desc += f" with rating >= {last_min_rating}"

        query_embedding = sentence_model.encode([search_desc])
        distances, indices = index.search(query_embedding, len(df))

        results = []
        used_indices = set()

        for idx in indices[0]:
            if idx in shown_indices or idx in used_indices:
                continue

            restaurant = df.iloc[idx]
            if restaurant['rating'] < last_min_rating:
                continue

            if last_preferences:
                match_text = restaurant['description'].lower()
                if not all(pref.lower() in match_text for pref in last_preferences):
                    continue

            name = restaurant['name']
            city = restaurant['city']
            rating = restaurant['rating']
            review_count = restaurant['review_count']
            address = restaurant['address']
            phone = restaurant['phone']
            url = restaurant['url']

            format_prompt = f"""
Create a friendly message for this burrito restaurant:
Name: {name}
City: {city}
Address: {address}
Rating: {rating}⭐
Reviews: {review_count} reviews
Phone: {phone}
URL: {url}
"""
            try:
                response = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[{
                        "role": "user",
                        "content": [{"type": "text", "text": format_prompt}]
                    }]
                )
                formatted_response = response.choices[0].message.content.strip()
            except Exception as e:
                formatted_response = f"Check out {name} at {address}!"

            shown_indices.add(idx)
            used_indices.add(idx)
            results.append(formatted_response)

            if len(results) >= num_results:
                break

        if not results:
            print("😕 Sorry, I couldn't find any burrito spots for your request.")
        else:
            for i, result in enumerate(results):
                print(f"🍽️ {i+1}. {result}\n")

# run chatbot
if __name__ == '__main__':
    chatbot()
