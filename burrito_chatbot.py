import os
import re  # ✅ For extracting numbers from user input
import openai
import faiss
import pandas as pd
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv  # ✅ Load .env file

# -------------------------------
# 🔧 Configuration
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
# 📥 Step 1: Load the Data and FAISS Index
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
# 🔍 Step 2: Load SentenceTransformer Model
# -------------------------------
sentence_model = SentenceTransformer('all-MiniLM-L6-v2')

# -------------------------------
# 🤖 Utility Functions
# -------------------------------

# Word-to-number mapping
word_to_number = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 
    'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 
    'nineteen': 19, 'twenty': 20
}

def extract_number_from_text(text):
    """Extracts the first number (word or digit) from the user's query. Defaults to 3 if no number is found."""
    # Extract digits (e.g., 1, 2, 10, etc.)
    digit_numbers = re.findall(r'\d+', text)
    if digit_numbers:
        return int(digit_numbers[0])
    
    # Extract number words (e.g., "one", "two", "three")
    for word in text.split():
        if word.lower() in word_to_number:
            return word_to_number[word.lower()]

    return 3  # Default to 3 if no number is found

# -------------------------------
# 🤖 Step 3: Chatbot Function (Sync)
# -------------------------------
def chatbot():
    print("\n🤖 Welcome to the Dublin Burrito Finder Bot!")
    print("Ask me anything about burrito restaurants (e.g., 'Where can I get a spicy burrito in Dublin?').")
    print("Type 'exit' to quit.\n")
    
    while True:
        user_input = input("You: ")
        
        if user_input.lower() in ['exit', 'quit']:
            print("👋 Goodbye!")
            break

        # 🧠 Step 1: Rephrase the query
        prompt = f"Rephrase this query to make it simple and clear for searching burrito restaurant descriptions: '{user_input}'"
        try:
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{
                    "role": "user",
                    "content": [{"type": "text", "text": prompt}]
                }]
            )
            search_query = response.choices[0].message.content.strip()
			#print(f"\n🔍 LLM Rephrased Query: {search_query}\n")
        except Exception as e:
            print(f"❌ Error during rephrasing: {e}")
            continue

        # 🧮 Step 2: Determine how many burrito spots to recommend
        num_recommendations = extract_number_from_text(user_input)

        # 🧠 Step 3: Encode the rephrased query into an embedding
        query_embedding = sentence_model.encode([search_query])
        
        # 🔍 Step 4: Use FAISS to search for the most similar restaurant descriptions
        k = max(1, min(20, num_recommendations))  # Restrict k between 1 and 20
        distances, indices = index.search(query_embedding, k)
		# print(f"Distances: {distances}")
        # print(f"Indices: {indices}")

        unique_results = set()  # Keep track of unique responses to avoid duplicates
        results = []

        for i, idx in enumerate(indices[0]):
            if distances[0][i] < 2.0:  # Filter on similarity (distance < 2.0)
                restaurant = df.iloc[idx]
                name = restaurant['name']
                city = restaurant['city']
                rating = restaurant['rating']
                review_count = restaurant['review_count']
                address = restaurant['address']
                phone = restaurant['phone']
                url = restaurant['url']
                
                prompt = f"Create a friendly message for this burrito restaurant:\nName: {name}\nCity: {city}\nAddress: {address}\nRating: {rating}⭐\nReviews: {review_count} reviews\nPhone: {phone}\nURL: {url}"
                
                try:
                    response = client.chat.completions.create(
                        model="gpt-4o-mini",
                        messages=[{
                            "role": "user",
                            "content": [{"type": "text", "text": prompt}]
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
        
        print("Ask me another question or type 'exit' to quit.\n")

# -------------------------------
# 🚀 Run the Chatbot
# -------------------------------
if __name__ == '__main__':
    chatbot()