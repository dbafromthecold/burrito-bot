import os
import re
import openai
import faiss
import pandas as pd
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv 
from prompt_toolkit import prompt
from prompt_toolkit.styles import Style
from word2number import w2n 


# === File Paths ===
CSV_FILE = 'processed_burrito_data.csv'
FAISS_INDEX_FILE = 'burrito_index.faiss'


# === Load Environment Variables ===
load_dotenv()
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
OPENAI_ORG = os.getenv('OPENAI_ORG')
OPENAI_PROJECT = os.getenv('OPENAI_PROJECT')


# === Initialize OpenAI Client ===
client = openai.Client(
    api_key=OPENAI_API_KEY,
    organization=OPENAI_ORG,
    project=OPENAI_PROJECT
)


# === Load Data and Embeddings ===
if not os.path.exists(CSV_FILE):
    raise FileNotFoundError(f"CSV file '{CSV_FILE}' not found.")
if not os.path.exists(FAISS_INDEX_FILE):
    raise FileNotFoundError(f"FAISS index file '{FAISS_INDEX_FILE}' not found.")

df = pd.read_csv(CSV_FILE)
index = faiss.read_index(FAISS_INDEX_FILE)
sentence_model = SentenceTransformer('all-MiniLM-L6-v2')


# === Helper Functions ===

def extract_number_from_text(text):
    """Extracts the first number from the user's query (e.g., 'three' → 3)."""
    digit_numbers = re.findall(r'\d+', text)
    if digit_numbers:
        return int(digit_numbers[0])
    for word in text.split():
        try:
            return w2n.word_to_num(word)
        except ValueError:
            continue
    return 3  # default

def extract_min_rating(text):
    """Extract a minimum star rating from user input if mentioned."""
    match = re.search(r'(\d+(\.\d+)?)\s*stars?', text.lower())
    if match:
        return float(match.group(1))
    return None


# === Main Chatbot Function ===

def chatbot():
    print("\n🌯 Welcome to the Dublin Burrito Bot!")
    print("❓ Ask me anything about burrito restaurants (e.g., 'Show me 5 burrito places over 4 stars in Dublin.').\n")

    style = Style.from_dict({
        'prompt': 'bold #00FFFF',
        '': 'bold #FFA500'
    })

    while True:
        user_input = prompt('You: ', style=style)
        print("\n")

        if user_input.lower() in ['exit', 'quit', 'bah']:
            print("👋 Goodbye!\n")
            break

        # Rephrase query with OpenAI
        query_prompt = f"Rephrase this query to make it simple and clear for searching burrito restaurant descriptions: '{user_input}'"
        try:
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{
                    "role": "user",
                    "content": [{"type": "text", "text": query_prompt}]
                }]
            )
            search_query = response.choices[0].message.content.strip()
        except Exception as e:
            print(f"❌ Error during rephrasing: {e}")
            continue

        # Extract filters
        num_recommendations = extract_number_from_text(user_input)
        min_rating = extract_min_rating(user_input)

        if min_rating:
            print(f"🔍 Searching for places rated {min_rating}⭐ or higher...\n")

        # Encode the rephrased query
        query_embedding = sentence_model.encode([search_query])
        
        # Search FAISS (get more than needed to allow for filtering)
        distances, indices = index.search(query_embedding, 30)

        unique_results = set()
        results = []

        for i, idx in enumerate(indices[0]):
            if distances[0][i] < 2.0:
                restaurant = df.iloc[idx]

                # Filter by rating
                if min_rating is not None and restaurant['rating'] < min_rating:
                    continue

                name = restaurant['name']
                city = restaurant['city']
                rating = restaurant['rating']
                review_count = restaurant['review_count']
                address = restaurant['address']
                phone = restaurant['phone']
                url = restaurant['url']

                query_prompt = f"""Create a friendly message for this burrito restaurant:
Name: {name}
City: {city}
Address: {address}
Rating: {rating}⭐
Reviews: {review_count} reviews
Phone: {phone}
URL: {url}"""

                try:
                    response = client.chat.completions.create(
                        model="gpt-4o-mini",
                        messages=[{
                            "role": "user",
                            "content": [{"type": "text", "text": query_prompt}]
                        }]
                    )
                    formatted_response = response.choices[0].message.content.strip()
                except Exception:
                    formatted_response = f"Try {name} at {address}, rated {rating} stars."

                if formatted_response not in unique_results:
                    unique_results.add(formatted_response)
                    results.append(formatted_response)

                if len(results) >= num_recommendations:
                    break

        # Display results
        if len(results) == 0:
            print("😕 Sorry, I couldn't find any burrito spots for your request.")
        else:
            for i, result in enumerate(results):
                print(f"🍽️ {i+1}. {result}\n")


# === Run the Bot ===
if __name__ == '__main__':
    chatbot()
