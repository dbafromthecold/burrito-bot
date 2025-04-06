import pandas as pd
from sentence_transformers import SentenceTransformer
import faiss
import os

# set names for input/output files
DATA_FILE = 'dublin_burrito_restaurants.csv'
PROCESSED_CSV = 'processed_burrito_data.csv'
FAISS_INDEX_FILE = 'burrito_index.faiss'

# load csv containing yelp data
if not os.path.exists(DATA_FILE):
    raise FileNotFoundError(f"Data file '{DATA_FILE}' not found. Please ensure it's in the current directory.")
df = pd.read_csv(DATA_FILE)

# confirm all required columns are in the csv
required_columns = ['name', 'city', 'rating', 'review_count', 'address', 'phone', 'url']
for col in required_columns:
    if col not in df.columns:
        raise ValueError(f"Missing required column: '{col}' in {DATA_FILE}. Please check your data file.")

print(f"✅ Successfully loaded {len(df)} rows from '{DATA_FILE}'")
print(df.head())

# remove any rows with missing name, city, or address
df = df.dropna(subset=['name', 'city', 'address'])

# combine the name, city, and address into a single descriptive text
df['description'] = (
    df['name'] + ' at ' + df['address'] + ' in ' + df['city'] +
    '. Rating: ' + df['rating'].astype(str) + ' stars.' +
    ' Based on ' + df['review_count'].astype(str) + ' reviews.'
)

# print some cleansed data
print("\n📋 Sample cleaned descriptions:")
print(df[['name', 'description']].head())

# load embedding model
print("\n🔄 Loading embedding model (this may take a minute)...")
model = SentenceTransformer('all-MiniLM-L6-v2')

# create embeddings for each restaurant description
print("\n🔄 Generating embeddings for each burrito restaurant...")
embeddings = model.encode(df['description'].tolist(), show_progress_bar=True)

# create a FAISS index to store the embeddings for fast retrieval
d = embeddings.shape[1]  # dimension of the embeddings
index = faiss.IndexFlatL2(d)  # L2 similarity (distance)
index.add(embeddings)  # add the embeddings to the FAISS index

# save FAISS index
faiss.write_index(index, FAISS_INDEX_FILE)
print(f"FAISS index saved as '{FAISS_INDEX_FILE}'")

# save the processed data as a new CSV file
df.to_csv(PROCESSED_CSV, index=False)
print(f"Processed data saved as '{PROCESSED_CSV}'")

# Final message
print("\nData processing complete! The burrito chatbot is ready to use.")
