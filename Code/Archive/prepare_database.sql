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



CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'XXXXXXXXXXXXXXXXXXXX';  
GO


CREATE DATABASE SCOPED CREDENTIAL [https://burrito-bot-ai.openai.azure.com]
WITH IDENTITY = 'HTTPEndpointHeaders', SECRET = N'{"api-key":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}'
GO


CREATE EXTERNAL MODEL [text-embedding-3-small]
WITH (
    LOCATION = 'ENDPOINT',
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