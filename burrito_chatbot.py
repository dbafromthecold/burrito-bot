import os
import re
import openai
import faiss
import pandas as pd
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv 
from prompt_toolkit import prompt  # ✅ Imported directly
from prompt_toolkit.styles import Style
from word2number import w2n  # ✅ Import word2number

# -------------------------------
# Configuration
# -------------------------------

CSV_FILE = 'processed_burrito_data.csv'
FAISS_INDEX_FILE = 'burrito_index.faiss'

load_dotenv()  # Load .env file

# Get the API Key, Organization, and Project from the environment variables
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
OPENAI_ORG = os.getenv('OPENAI_ORG')
OPENAI_PROJECT = os.getenv('OPENAI_PROJECT')

# Initialize the OpenAI client
client = openai.Client(
    api_key=OPENAI_API_KEY,
    organization=OPENAI_ORG,
    project=OPENAI_PROJECT
)

# -------------------------------
# Step 1: Load the Data and FAISS Index
# -------------------------------

if not os.path.exists(CSV_FILE):
    raise FileNotFoundError(f"CSV file '{CSV_FILE}' not found. Please ensure it's in the current directory.")
if not os.path.exists(FAISS_INDEX_FILE):
    raise FileNotFoundError(f"FAISS index file '{FAISS_INDEX_FILE}' not found. Please ensure it's in the current directory.")

# Load the processed burrito data CSV
df = pd.read_csv(CSV_FILE)

# Load the FAISS index
index = faiss.read_index(FAISS_INDEX_FILE)

# -------------------------------
# Step 2: Load SentenceTransformer Model
# -------------------------------

sentence_model = SentenceTransformer('all-MiniLM-L6-v2')

# -------------------------------
# Utility Functions
# -------------------------------

def extract_number_from_text(text):
    """Extracts the first number (word or digit) from the user's query. Defaults to 3 if no number is found."""
    # Extract digit-based numbers (like 1, 2, 10, etc.)
    digit_numbers = re.findall(r'\d+', text)
    if digit_numbers:
        return int(digit_numbers[0])  # Return the first number found
    
    # Extract number words (like "one", "twelve", "twenty-one")
    for word in text.split():
        try:
            return w2n.word_to_num(word)  # Use word2number to convert
        except ValueError:
            pass  # If the word isn't a number, move to the next one

    return 3  # Default to 3 if no number is found

# -------------------------------
# Step 3: Chatbot Function
# -------------------------------

def chatbot():
    print("\n🌯 Welcome to the Dublin Burrito Bot!")
    print("❓ Ask me anything about burrito restaurants (e.g., 'Where can I get a spicy burrito in Dublin?').\n")
    #print("Type 'exit' to quit.\n")

    style = Style.from_dict({
        'prompt': 'bold #00FFFF',  # Cyan prompt text
        '': 'bold #FFA500'          # Orange input text
    })

    while True:
        user_input = prompt('You: ', style=style)
        #print(f"You said: {user_input}\n")
        print("\n")

        if user_input.lower() in ['exit', 'quit', 'bah']:
            print("👋 Goodbye!\n")
            break

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

        # Extract number of burrito spots to recommend
        num_recommendations = extract_number_from_text(user_input)
        
        # Log the extracted number
        #print(f"🔢 Extracted number of recommendations: {num_recommendations} (default: 3)")

        query_embedding = sentence_model.encode([search_query])
        
        # Set k to be the number of recommendations, bounded between 1 and 20
        k = max(1, min(20, num_recommendations))
        distances, indices = index.search(query_embedding, k)

        unique_results = set()
        results = []

        for i, idx in enumerate(indices[0]):
            if distances[0][i] < 2.0:
                restaurant = df.iloc[idx]
                name = restaurant['name']
                city = restaurant['city']
                rating = restaurant['rating']
                review_count = restaurant['review_count']
                address = restaurant['address']
                phone = restaurant['phone']
                url = restaurant['url']
                
                query_prompt = f"Create a friendly message for this burrito restaurant:\nName: {name}\nCity: {city}\nAddress: {address}\nRating: {rating}⭐\nReviews: {review_count} reviews\nPhone: {phone}\nURL: {url}"
                
                try:
                    response = client.chat.completions.create(
                        model="gpt-4o-mini",
                        messages=[{
                            "role": "user",
                            "content": [{"type": "text", "text": query_prompt}]
                        }]
                    )
                    formatted_response = response.choices[0].message.content.strip()
                except Exception as e:
                    formatted_response = "Try this burrito spot, it's awesome!"

                if formatted_response not in unique_results:
                    unique_results.add(formatted_response)
                    results.append(formatted_response)
        
        if len(results) == 0:
            print("😕 Sorry, I couldn't find any burrito spots for your request.")
        else:
            for i, result in enumerate(results):
                print(f"🍽️ {i+1}. {result}\n")

# -------------------------------
# Run the Chatbot
# -------------------------------

if __name__ == '__main__':
    chatbot()