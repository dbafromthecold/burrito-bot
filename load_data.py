import pandas as pd
from sentence_transformers import SentenceTransformer
import faiss
import os

# -------------------------------
# 🔧 Configuration
# -------------------------------
# Set the file name of your burrito data (update this if needed)
DATA_FILE = 'dublin_burrito_restaurants.csv'  # Replace this with your CSV file name
PROCESSED_CSV = 'processed_burrito_data.csv'
FAISS_INDEX_FILE = 'burrito_index.faiss'

# -------------------------------
# 📥 Step 1: Load the CSV Data
# -------------------------------
if not os.path.exists(DATA_FILE):
    raise FileNotFoundError(f"Data file '{DATA_FILE}' not found. Please ensure it's in the current directory.")

# Load the CSV data
df = pd.read_csv(DATA_FILE)

# Check if all required columns are in the data
required_columns = ['name', 'city', 'rating', 'review_count', 'address', 'phone', 'url']
for col in required_columns:
    if col not in df.columns:
        raise ValueError(f"Missing required column: '{col}' in {DATA_FILE}. Please check your data file.")

print(f"✅ Successfully loaded {len(df)} rows from '{DATA_FILE}'")
print(df.head())

# -------------------------------
# 🧹 Step 2: Data Cleaning
# -------------------------------
# Remove any rows with missing name, city, or address
df = df.dropna(subset=['name', 'city', 'address'])

# Combine the name, city, and address into a single descriptive text
df['description'] = df['name'] + ' located in ' + df['city'] + ' at ' + df['address']

# Print some cleaned data
print("\n📋 Sample cleaned descriptions:")
print(df[['name', 'description']].head())

# -------------------------------
# 🔍 Step 3: Create Embeddings Using SentenceTransformer
# -------------------------------
print("\n🔄 Loading embedding model (this may take a minute)...")
model = SentenceTransformer('all-MiniLM-L6-v2')

# Generate embeddings for each restaurant description
print("\n🔄 Generating embeddings for each burrito restaurant...")
embeddings = model.encode(df['description'].tolist(), show_progress_bar=True)

# -------------------------------
# 📦 Step 4: Create FAISS Index
# -------------------------------
# Create a FAISS index to store the embeddings for fast retrieval
d = embeddings.shape[1]  # Dimension of the embeddings
index = faiss.IndexFlatL2(d)  # L2 similarity (distance)
index.add(embeddings)  # Add the embeddings to the FAISS index

# -------------------------------
# 💾 Step 5: Save the FAISS Index and CSV
# -------------------------------
# Save the FAISS index for later use
faiss.write_index(index, FAISS_INDEX_FILE)
print(f"✅ FAISS index saved as '{FAISS_INDEX_FILE}'")

# Save the processed data as a new CSV file
df.to_csv(PROCESSED_CSV, index=False)
print(f"✅ Processed data saved as '{PROCESSED_CSV}'")

# Final message
print("\n🎉 Data processing complete! The burrito chatbot is ready to use.")
