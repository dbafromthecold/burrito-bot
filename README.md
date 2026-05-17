# The Burrito Bot 🌯

An AI-powered semantic similarity search application that provides burrito restaurant recommendations using SQL Server 2025 vector search capabilities.

## 📋 Overview

The Burrito Bot demonstrates the practical application of vector embeddings and semantic search in SQL Server 2025. By converting restaurant reviews and metadata into vector embeddings, the system can intelligently match user queries to the most relevant burrito restaurants based on semantic similarity rather than keyword matching.

## 🏗️ Repository Structure

### Code Directory
SQL Server scripts that comprise the complete data pipeline:

- **`1. Create Database.sql`** - Database initialization and schema setup
- **`2. Create Data Tables.sql`** - Main tables for storing restaurant and review data
- **`3a. Pull Restaurant Metadata.sql`** - Scripts for retrieving restaurant metadata
- **`3b. Pull Restaurant Reviews.sql`** - Scripts for retrieving restaurant reviews
- **`4. Create Raw Data Tables.sql`** - Staging tables for raw data
- **`5. Import Raw Data.sql`** - Load raw data from external sources
- **`6. Import Data to Main Tables.sql`** - Transform and load data into main tables
- **`7. Create External Model.sql`** - Configure external AI model for embeddings
- **`8. Generate Embeddings.sql`** - Generate vector embeddings for all reviews
- **`9. VECTOR DISTANCE.sql`** - Calculate vector distances between embeddings
- **`10. VECTOR SEARCH.sql`** - Perform semantic similarity searches
- **`11. Comparing Search Results.sql`** - Compare different search approaches
- **`12. VECTOR SEARCH Stored Procedure.sql`** - Stored procedure wrapper for search functionality

### Data Directory
Scripts and data files for data acquisition and visualization:

- **PowerShell Scripts** - Automated data collection from Google Maps API
  - `pull place ids from google maps.ps1` - Extract restaurant identifiers
  - `pull review data from google maps.ps1` - Collect restaurant reviews
  - `pull data from google maps - old api.ps1` - Legacy API integration
- **Raw Data/** - Intermediate data storage (place IDs, reviews, archive)
- **Visualise Data/** - Embedding visualization datasets
  - `Embeddings One/` - Restaurant metadata embedding set
  - `Embeddings Two/` - Restaurant review embedding set

## 🚀 How It Works

### Data Pipeline

1. **Collection** - PowerShell scripts fetch restaurant metadata and reviews from Google Maps
2. **Staging** - Raw data is imported into staging tables
3. **Processing** - Data is transformed and loaded into main tables
4. **Embeddings** - SQL Server generates vector embeddings using AI models
5. **Search** - Semantic similarity queries find the most relevant restaurants

### Vector Search

The system uses vector embeddings to understand the semantic meaning of reviews and queries. When a user searches for "amazing burritos," the system finds restaurants with similar review content rather than exact keyword matches.

## 📚 Resources

### Official Documentation

- [Vector Search and Vector Indexes in SQL Server](https://learn.microsoft.com/en-us/sql/sql-server/ai/vectors)
- [Vector and Embeddings FAQ](https://learn.microsoft.com/en-us/sql/sql-server/ai/vectors-faq)
- [AI_GENERATE_EMBEDDINGS Function](https://learn.microsoft.com/en-gb/sql/t-sql/functions/ai-generate-embeddings-transact-sql)

### Learning Resources

- [Massive Text Embedding Benchmark](https://huggingface.co/spaces/mteb/leaderboard)
- [Efficiently and Elegantly Modeling Embeddings in Azure SQL and SQL Server](https://devblogs.microsoft.com/azure-sql/efficiently-and-elegantly-modeling-embeddings-in-azure-sql-and-sql-server)
- [Vector Similarity Explained](https://www.pinecone.io/learn/vector-similarity)
- [Cosine Similarity and Cosine Distance](https://docs.singlestore.com/cloud/reference/sql-reference/vector-functions/cosine-similarity-and-cosine-distance)

### Visualization & Tools

- [TensorFlow Embedding Projector](https://projector.tensorflow.org)
- [Getting Started with Vector Search in SQL Server 2025 Using Ollama](https://www.nocentino.com/posts/2025-05-19-ollama-sql-faststart/)

## 📊 Presentation Materials

- **Blog Post**: [The Burrito Bot - AI-Powered Search in SQL Server 2025](https://dbafromthecold.com/2026/03/27/the-burrito-bot-ai-powered-search-in-sql-server-2025/)
- **Slides**: [Interactive Presentation](https://dbafromthecold.github.io/burrito-bot)

## 🎯 Key Features

- **Semantic Search** - Find restaurants based on review content similarity, not just keywords
- **Vector Embeddings** - AI-generated embeddings for intelligent matching
- **Scalable Architecture** - Leverages SQL Server's native vector capabilities
- **Real-World Data** - Uses actual Google Maps restaurant and review data
- **Comparison Tools** - Analyze different search methodologies

## 🤝 Contributing

This repository welcomes contributions! If you have:

- Improvements to the pipeline or queries
- Additional data sources or visualization approaches
- Bug fixes or optimizations
- Documentation enhancements

Please submit a pull request with your changes.

## 📄 Licence

This project is provided as-is for educational and reference purposes.

## 👨‍💻 Author

**Andrew Pruski** (@dbafromthecold)
- Blog: [dbafromthecold.com](https://dbafromthecold.com)
- Email: dbafromthecold@gmail.com
- GitHub: [github.com/dbafromthecold](https://github.com/dbafromthecold)

---

*Built with ❤️ for the SQL Server and AI community*
