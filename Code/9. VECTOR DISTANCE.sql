/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Vector Distance
***************************************************************************
**************************************************************************/



USE [burrito-bot-db];
GO



-- are those vectors normalised?
SELECT VECTOR_NORM(embeddings, 'norm2') AS length
FROM embeddings.restaurant_review_embeddings;
GO



-- let's perform a search using VECTOR_DISTANCE() using cosine distance
-- include the actual execution plan
-- 0: identical vectors 2: opposing vectors
DECLARE @search_text   NVARCHAR(MAX) = 'Find me a restaurant with a good atmosphere';
DECLARE @search_vector VECTOR(1536)  = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL [text-embedding-3-small]);

SELECT TOP(1)
	r.[id], 
	r.[name], 
	r.[city], 
	r.[rating], 
	r.[review_count], 
	r.[address], 
	r.[phone], 
	r.[url],
	VECTOR_DISTANCE('cosine', @search_vector, e.embeddings) AS distance
FROM [data].[restaurants] r
INNER JOIN [embeddings].[restaurant_review_embeddings] e ON r.id = e.restaurant_id
ORDER BY distance;
GO



-- let's have a look at the reviews to see why that restaurant was selected
SELECT rv.restaurant_id, rv.review_text
FROM [data].[reviews] rv
INNER JOIN [data].[restaurants] r ON rv.restaurant_id = r.id
WHERE r.name = 'Texas Steakout'
ORDER BY rv.restaurant_id ASC;
GO



-- let's do one more search using VECTOR_DISTANCE()
DECLARE @search_text   NVARCHAR(MAX) = 'Find me a restaurant with authentic mexican food';
DECLARE @search_vector VECTOR(1536)  = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL [text-embedding-3-small]);

SELECT TOP(1)
	r.[id], 
	r.[name], 
	r.[city], 
	r.[rating], 
	r.[review_count], 
	r.[address], 
	r.[phone], 
	r.[url],
	VECTOR_DISTANCE('cosine', @search_vector, e.embeddings) AS distance
FROM [data].[restaurants] r
INNER JOIN [embeddings].[restaurant_review_embeddings] e ON r.id = e.restaurant_id
ORDER BY distance;
GO



-- and have a look at the reviews to see why that restaurant was selected
SELECT rv.restaurant_id, rv.review_text
FROM [data].[reviews] rv
INNER JOIN [data].[restaurants] r ON rv.restaurant_id = r.id
WHERE r.name = 'Salsa - Authentic Mexican Food'
AND r.city = 'Dublin'
ORDER BY rv.restaurant_id ASC;
GO



-- let's have a look at the other metrics
-- cosine distance      [0, 2]	 0: identical vectors 2: opposing vectors
-- negative dot product	[-∞, +∞] Smaller numbers indicate more similar vectors
-- euclidean distance   [0, +∞]  0: identical vectors
DECLARE @search_text   NVARCHAR(MAX) = 'Find me a restaurant with a good atmosphere';
DECLARE @search_vector VECTOR(1536)  = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL [text-embedding-3-small]);

SELECT TOP(10)
	r.[id], 
	r.[name], 
	r.[city], 
	r.[rating], 
	r.[review_count], 
	VECTOR_DISTANCE('cosine', @search_vector, e.embeddings) AS cosine--,
	--VECTOR_DISTANCE('dot', @search_vector, e.embeddings) AS dot,
	--CAST(VECTOR_DISTANCE('cosine', @search_vector, e.embeddings) - (1 + VECTOR_DISTANCE('dot', @search_vector, e.embeddings)) AS DECIMAL(20,18))  AS difference
	--VECTOR_DISTANCE('euclidean', @search_vector, e.embeddings) AS euclidean
FROM [data].[restaurants] r
INNER JOIN [embeddings].[restaurant_review_embeddings] e ON r.id = e.restaurant_id
ORDER BY cosine;
GO