/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Comparing search functions
***************************************************************************
**************************************************************************/



-- set text for search and get embedding
DECLARE @search_text   NVARCHAR(MAX) = 'Find me a restaurant with a good atmosphere';
DECLARE @search_vector VECTOR(1536)  = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL [text-embedding-3-small]);



-- perform k-NN search
SELECT TOP(10)
	r.[id], 
	r.[name], 
	r.[city], 
	r.[rating], 
	r.[review_count], 
	r.[address], 
	r.[phone], 
	r.[url],
	VECTOR_DISTANCE('cosine', @search_vector, e.embeddings) AS distance
INTO #exact
FROM [data].[restaurants] r
INNER JOIN [embeddings].[restaurant_review_embeddings] e ON r.id = e.restaurant_id
ORDER BY distance;



-- perform ANN search
SELECT
    r.[id]              AS [id],
    r.[name]            AS [Name], 
    r.[city]            AS [City], 
    ROUND(r.[rating],1) AS [Rating], 
    r.[review_count]    AS [Review Count], 
    r.[address]         AS [Address], 
    r.[phone]           AS [Phone Number], 
    r.[url]             AS [URL],
    vs.distance
INTO #approx
FROM VECTOR_SEARCH(
    TABLE      = [embeddings].[restaurant_review_embeddings] AS e,
    COLUMN     = [embeddings],
    SIMILAR_TO = @search_vector,
    METRIC     = 'cosine',
    TOP_N      = 10
) AS vs
INNER JOIN [data].[restaurants] r ON r.id = e.restaurant_id
ORDER BY vs.distance;



-- check the results
SELECT * FROM #exact;
SELECT * FROM #approx;



-- Calculate Recall@K
-- Count how many ANN results also appear in the exact top-K results
-- Divide by K (the number of relevant results) to get a proportion between 0 and 1
SELECT COUNT(*) * 1.0 / 10 AS recall
FROM #approx a
INNER JOIN #exact e ON a.id = e.id;
GO



-- drop tables (make script re-runnable)
DROP TABLE #approx;
DROP TABLE #exact;
GO