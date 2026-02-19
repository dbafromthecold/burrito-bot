USE [burrito-bot-db]
GO



/********************************************************************************************************************

Create table to hold data and embeddings

********************************************************************************************************************/



CREATE TABLE [dbo].[restaurants](
	[id]			INT IDENTITY(1,1) CONSTRAINT [pk_restaurants] PRIMARY KEY,
	[name]			[NVARCHAR](50) NOT NULL,
	[city]			[NVARCHAR](50) NOT NULL,
	[rating]		[FLOAT] NOT NULL,
	[review_count]	[SMALLINT] NOT NULL,
	[address]		[NVARCHAR](100) NOT NULL,
	[phone]			[BIGINT] NULL,
	[url]			[NVARCHAR](200) NOT NULL,
	[chunk]			[NVARCHAR](2000),
	[embeddings]	[VECTOR](1536)
) ON [PRIMARY]
GO


INSERT INTO dbo.restaurants
([name], [city], [rating], [review_count], [address], [phone], [url])
SELECT *
FROM [dbo].[dublin_burrito_restaurants_raw];
GO



SELECT * FROM dbo.restaurants;
GO



/********************************************************************************************************************

Generate embeddings

********************************************************************************************************************/


UPDATE r
SET 
 [chunk] = r.Name + ' ' + r.City  + ' ' + CONVERT(NVARCHAR(50),r.Rating)  + ' ' + CONVERT(NVARCHAR(4),r.review_count)  + ' ' + r.Address,
 [embeddings] = AI_GENERATE_EMBEDDINGS(r.Name + ' ' + r.City  + ' ' + CONVERT(NVARCHAR(50),r.Rating)  + ' ' + CONVERT(NVARCHAR(4),r.review_count)  + ' ' + r.Address USE MODEL [text-embedding-3-small])
FROM [dbo].[restaurants] r;
GO


SELECT * FROM dbo.restaurants;
GO



/********************************************************************************************************************

Perform a vector search

********************************************************************************************************************/



DECLARE @search_text NVARCHAR(MAX) = 'Find me a restaurant with a 4 star rating';
DECLARE @search_vector VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@search_text USE MODEL [text-embedding-3-small]);

SELECT TOP(1)
	r.[id], 
	r.[name], 
	r.[city], 
	r.[rating], 
	r.[review_count], 
	r.[address], 
	r.[phone], 
	r.[url],
	vector_distance('cosine', @search_vector, r.embeddings) AS distance
FROM [dbo].[restaurants] r
ORDER BY distance;
GO



/********************************************************************************************************************

Creating a vector index

********************************************************************************************************************/



DBCC TRACEON (466, 474, 13981, -1);
GO

CREATE VECTOR INDEX vec_idx ON [dbo].[restaurants]([embeddings])
WITH (
    metric = 'cosine',
    type = 'diskann',
    maxdop = 8
);
GO



/********************************************************************************************************************

Creating a stored procedure to perform searches

********************************************************************************************************************/


CREATE OR ALTER PROCEDURE [dbo].[search_restaurants]
    @question       NVARCHAR(MAX),
    @num_results    INT = 5
AS
BEGIN
    DECLARE @search_vector VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@question USE MODEL [text-embedding-3-small]);

    SELECT  --r.[id], 
			r.[name] AS [Name], 
			r.[city] AS [City], 
			ROUND(r.[rating],1) AS [Rating], 
			r.[review_count] AS [Review Count], 
			r.[address] AS [Address], 
			r.[phone] AS [Phone Number], 
			r.[url] AS [URL]
			--vector_distance('cosine', @search_vector, r.embeddings) AS distance
	FROM vector_search(
		TABLE		= [dbo].[restaurants] AS r,
		COLUMN		= [embeddings],
		SIMILAR_TO	= @search_vector,
		METRIC		= 'cosine',
		TOP_N		= @num_results
		) AS s
    ORDER BY s.distance ASC;
END
GO



EXEC dbo.search_restaurants
    @question = 'Find me a restaurant in Dame Street',
    @num_results= 5