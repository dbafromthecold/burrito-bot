/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Vector Search
***************************************************************************
**************************************************************************/



USE [burrito-bot-db];
GO



-- PREVIEW_FEATURES is a pre-requisite as of current SQL version
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON
GO



-- let's get the size of the table before we create that index
EXEC sp_spaceused 'embeddings.restaurant_review_embeddings'
GO



-- creating the index referencing the diskann algorithm (only one supported)
-- include the actual execution plan
CREATE VECTOR INDEX vec_idx ON [embeddings].[restaurant_review_embeddings]([embeddings])
WITH (
    METRIC  = 'cosine', -- euclidean and dot also supported
    TYPE    = 'diskann',
    MAXDOP  = 8 -- set the parallelism of the create index operation - currently ignored!
);
GO



/*************************************************************************************************
let's inspect the data of that index
DBCC IND
DBCC PAGE


*************************************************************************************************/



-- also, let's try to update the data in table...it's now read only!
INSERT INTO [embeddings].[restaurant_review_embeddings]
           ([restaurant_id]
           ,[embeddings])
     VALUES
           (999
           ,NULL)
GO



-- and let's have a look at the size of the table now
EXEC sp_spaceused 'embeddings.restaurant_review_embeddings'
GO



-- let's perform a vector search! include actual execution plan
-- do we get different results from VECTOR_DISTANCE() ?
-- generating embeddings for our query
DECLARE @question       NVARCHAR(MAX) = 'Find me a restaurant with a good atmosphere';
DECLARE @search_vector  VECTOR(1536)  = AI_GENERATE_EMBEDDINGS(@question USE MODEL [text-embedding-3-small]);

SELECT
    r.[id]              AS [restaurant_id],
    r.[name]            AS [Name], 
    r.[city]            AS [City], 
    ROUND(r.[rating],1) AS [Rating], 
    r.[review_count]    AS [Review Count], 
    r.[address]         AS [Address], 
    r.[phone]           AS [Phone Number], 
    r.[url]             AS [URL],
    vs.distance
FROM VECTOR_SEARCH(
    TABLE      = [embeddings].[restaurant_review_embeddings] AS e,
    COLUMN     = [embeddings],
    SIMILAR_TO = @search_vector,
    METRIC     = 'cosine',
    TOP_N      = 5
) AS vs
INNER JOIN [data].[restaurants] r ON r.id = e.restaurant_id
ORDER BY vs.distance;
GO



-- let's have a look at the reviews for a couple of those results
SELECT rv.restaurant_id, rv.review_text
FROM [data].[reviews] rv
INNER JOIN [data].[restaurants] r ON rv.restaurant_id = r.id
WHERE r.name IN ('Texas Steakout','777')
ORDER BY rv.restaurant_id ASC;
GO



-- create a stored procedure to perform searches
CREATE OR ALTER PROCEDURE dbo.search_restaurants
    @question     NVARCHAR(MAX),
    @num_results  INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @search_vector VECTOR(1536) =
        AI_GENERATE_EMBEDDINGS(@question USE MODEL [text-embedding-3-small]);

    SELECT
        r.[name] AS [Name], 
        r.[city] AS [City], 
        ROUND(r.[rating],1) AS [Rating], 
        r.[review_count] AS [Review Count], 
        r.[address] AS [Address], 
        r.[phone] AS [Phone Number], 
        r.[url] AS [URL],
        vs.distance
    FROM VECTOR_SEARCH(
        TABLE      = [embeddings].[restaurant_review_embeddings] AS e,
        COLUMN     = [embeddings],
        SIMILAR_TO = @search_vector,
        METRIC     = 'cosine',
        TOP_N      = @num_results
    ) AS vs
    INNER JOIN [data].[restaurants] r ON r.id = e.restaurant_id
    ORDER BY vs.distance;
END
GO



-- let's test the stored procedure
EXEC dbo.search_restaurants
    @question = 'Where do people say the food reminds them of Mexico?',
    @num_results= 5;
GO



-- and have a look at the reviews for a couple of those results
SELECT rv.restaurant_id, rv.review_text
FROM [data].[reviews] rv
INNER JOIN [data].[restaurants] r ON rv.restaurant_id = r.id
WHERE r.name IN ('The Mex','Adobo Mexico')
ORDER BY rv.restaurant_id ASC;
GO



-- let's do one more!
EXEC dbo.search_restaurants
    @question = 'Good place for a casual date night?',
    @num_results= 5;
GO



-- and check the reviews again
SELECT rv.restaurant_id, rv.review_text
FROM [data].[reviews] rv
INNER JOIN [data].[restaurants] r ON rv.restaurant_id = r.id
WHERE r.name IN ('Texas Steakout','Town Square')
ORDER BY rv.restaurant_id ASC;
GO



-- anyone want to ask a question?
EXEC dbo.search_restaurants
    @question = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    @num_results= 5;
GO



-- check the reviews again
SELECT rv.restaurant_id, rv.review_text
FROM [data].[reviews] rv
INNER JOIN [data].[restaurants] r ON rv.restaurant_id = r.id
WHERE r.name IN ('XXXXXXXXXXXXXXX','XXXXXXXXXXXXXXX')
ORDER BY rv.restaurant_id ASC;
GO
