import os
import requests
import pandas as pd
from dotenv import load_dotenv  # ✅ Load .env file

load_dotenv()

# Set up Yelp API details
API_KEY = os.getenv('YELP_API_KEY')
headers = {'Authorization': f'Bearer {API_KEY}'}

def fetch_burrito_restaurants(city, limit=50):
    url = 'https://api.yelp.com/v3/businesses/search'
    params = {
        'term': 'burrito',
        'location': city,
        'limit': limit
    }
    response = requests.get(url, headers=headers, params=params)
    if response.status_code == 200:
        return response.json()['businesses']
    else:
        print(f"Failed to fetch data for {city}. Status code: {response.status_code}")
        return []

# List of cities you want to pull burrito restaurant data for
#cities = ['Los Angeles', 'San Francisco', 'Austin', 'New York','Dublin']
cities = ['Dublin']

# Collect data for each city
all_restaurants = []
for city in cities:
    restaurants = fetch_burrito_restaurants(city)
    for restaurant in restaurants:
        all_restaurants.append({
            'name': restaurant['name'],
            'city': city,
            'rating': restaurant['rating'],
            'review_count': restaurant['review_count'],
            'address': ' '.join(restaurant['location']['display_address']),
            'phone': restaurant.get('phone', 'N/A'),
            'url': restaurant.get('url', 'N/A')
        })

# Convert to DataFrame
df = pd.DataFrame(all_restaurants)

# Save to a CSV file
df.to_csv('dublin_burrito_restaurants.csv', index=False)

print("Data saved to 'dublin_burrito_restaurants.csv'")
