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



-- let's perform a search using VECTOR_DISTANCE()
-- include the actual execution plan
-- do we get different results using different distance metrics?
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
	--vector_distance('dot', @search_vector, e.embeddings) AS distance
	--vector_distance('euclidean', @search_vector, e.embeddings) AS distance
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
