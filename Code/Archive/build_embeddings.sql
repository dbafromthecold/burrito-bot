USE [burrito-bot-db]
GO

/********************************************************************************************************************

creating ai model to generate embeddings

********************************************************************************************************************/


CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'S0methingS@Str0ng!';  
GO


--DROP DATABASE SCOPED CREDENTIAL [https://burrito-bot-ai.openai.azure.com]


CREATE DATABASE SCOPED CREDENTIAL [https://burrito-bot-ai.openai.azure.com]
WITH IDENTITY = 'HTTPEndpointHeaders', SECRET = N'{"api-key":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}'
GO


--DROP EXTERNAL MODEL [text-embedding-3-small];


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


DECLARE @ret1 INT, @response1 NVARCHAR(MAX)
EXEC @ret1 = sp_invoke_external_rest_endpoint
    @url = N'https://burrito-bot-ai.openai.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-05-15',
    --@credential = [https://burrito-bot-ai.openai.azure.com],
	@headers = N'{"api-key":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}',
    @response = @response1 OUTPUT;
PRINT @response1


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

create table and generate embeddings

********************************************************************************************************************/


DROP TABLE IF EXISTS dbo.restaurants;
GO


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


INSERT INTO [dbo].[restaurants]
           ([place_id],
            [name]
           ,[city]
           ,[rating]
           ,[review_count]
           ,[address]
           ,[phone]
           ,[url])
SELECT  [place_id]
        ,[name]
        ,'XXXXXXXXXXXXXXXXX'
        ,[rating]
        ,[review_count]
        ,[address]
        ,[phone_number]
        ,'https://www.google.com/maps/place/?q=place_id:' + [place_id]
FROM [raw_data].[mexican_restaurants_XXXXXXXXXXXXXXXXXXXXX]
GO



SELECT * FROM dbo.restaurants;
GO


UPDATE r
SET 
 [chunk] = r.Name + ' ' + r.City  + ' ' + CONVERT(NVARCHAR(50),r.Rating)  + ' ' + CONVERT(NVARCHAR(4),r.review_count)  + ' ' + r.Address,
 [embeddings] = AI_GENERATE_EMBEDDINGS(r.Name + ' ' + r.City  + ' ' + CONVERT(NVARCHAR(50),r.Rating)  + ' ' + CONVERT(NVARCHAR(4),r.review_count)  + ' ' + r.Address USE MODEL [text-embedding-3-small])
FROM [dbo].[restaurants] r;
GO


SELECT * FROM dbo.restaurants;
GO



/********************************************************************************************************************

perform a vector search

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


DECLARE @search_text NVARCHAR(MAX) = 'Find me a restaurant with over 100 reviews';
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


DECLARE @search_text NVARCHAR(MAX) = 'Find me a restaurant in Mountjoy Square';
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

creating vector index

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

creating stored procedure

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