USE [burrito-bot-db]
GO


ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO


/********************************************************************************************************************

View raw data

********************************************************************************************************************/



SELECT * FROM [dbo].[dublin_burrito_restaurants_raw];
GO



/********************************************************************************************************************

Creating external model to generate embeddings

********************************************************************************************************************/



CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'S0methingS@Str0ng!';  
GO


CREATE DATABASE SCOPED CREDENTIAL [https://burrito-bot-ai.openai.azure.com]
WITH IDENTITY = 'HTTPEndpointHeaders', SECRET = N'{"api-key":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}'
GO


CREATE EXTERNAL MODEL [text-embedding-3-small]
WITH (
    LOCATION = 'https://burrito-bot-ai.openai.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-05-15',
    API_FORMAT = 'Azure OpenAI',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'text-embedding-3-large',
    CREDENTIAL = [https://burrito-bot-ai.openai.azure.com]
);
GO


EXEC sp_configure 'external rest endpoint enabled',1
RECONFIGURE;
GO



BEGIN
    DECLARE @result NVARCHAR(MAX);
    SET @result = (SELECT CONVERT(NVARCHAR(MAX), AI_GENERATE_EMBEDDINGS(N'test text' USE MODEL [text-embedding-3-small])))
    SELECT AI_GENERATE_EMBEDDINGS(N'test text' USE MODEL [text-embedding-3-small]) AS GeneratedEmbedding

    IF @result IS NOT NULL
        PRINT 'Model test successful. Result: ' + @result;
    ELSE
        PRINT 'Model test failer. No result returner.';
END;
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


INSERT INTO [embeddings].[restaurant_embeddings]
(
    restaurant_id,
    embeddings
)
SELECT
    r.id,
    AI_GENERATE_EMBEDDINGS(
        r.Name + ' ' +
        r.City + ' ' +
        CONVERT(NVARCHAR(50), r.Rating) + ' ' +
        CONVERT(NVARCHAR(4), r.review_count) + ' ' +
        r.Address
        USE MODEL [text-embedding-3-small]
    )
FROM dbo.restaurants r;



SELECT * 
FROM dbo.restaurants r
INNER JOIN [embeddings].[restaurant_embeddings] e ON r.id = e.restaurant_id;
GO



/********************************************************************************************************************

Perform a vector search

********************************************************************************************************************/



DECLARE @search_text NVARCHAR(MAX) = 'Find me a restaurant with a 5 star rating';
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
	vector_distance('cosine', @search_vector, e.embeddings) AS distance
FROM [dbo].[restaurants] r
INNER JOIN [embeddings].[restaurant_embeddings] e ON r.id = e.restaurant_id
ORDER BY distance;
GO



/********************************************************************************************************************

Creating a vector index

********************************************************************************************************************/



DBCC TRACEON (466, 474, 13981, -1);
GO

CREATE VECTOR INDEX vec_idx ON [embeddings].[restaurant_embeddings]([embeddings])
WITH (
    metric = 'cosine',
    type = 'diskann',
    maxdop = 8
);
GO



/********************************************************************************************************************

Creating a stored procedure to perform searches

********************************************************************************************************************/


CREATE OR ALTER PROCEDURE dbo.search_restaurants
    @question     NVARCHAR(MAX),
    @num_results  INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @search_vector VECTOR(1536) =
        AI_GENERATE_EMBEDDINGS(@question USE MODEL [text-embedding-3-small]);

    ;WITH vs AS
    (
        SELECT
            restaurant_id,
            distance
        FROM vector_search(
            TABLE      = [embeddings].[restaurant_embeddings],
            COLUMN     = [embeddings],
            SIMILAR_TO = @search_vector,
            METRIC     = 'cosine',
            TOP_N      = @num_results
        )
    )
    SELECT
        r.[name] AS [Name], 
		r.[city] AS [City], 
		ROUND(r.[rating],1) AS [Rating], 
		r.[review_count] AS [Review Count], 
		r.[address] AS [Address], 
		r.[phone] AS [Phone Number], 
		r.[url] AS [URL]
        --vs.distance
    FROM vs
    INNER JOIN dbo.restaurants r
        ON r.id = vs.restaurant_id
    ORDER BY vs.distance;
END
GO



EXEC dbo.search_restaurants
    @question = 'Find me a restaurant with a 3 star rating',
    @num_results= 5