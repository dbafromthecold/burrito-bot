/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Create external model
***************************************************************************
**************************************************************************/



USE [burrito-bot-db]
GO



-- create database master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Th1s1s@Str0ngP@assw0rd!';  
GO



-- create credential to hold API key used to access external model
CREATE DATABASE SCOPED CREDENTIAL [https://burrito-bot-ai.openai.azure.com]
WITH IDENTITY = 'HTTPEndpointHeaders', SECRET = N'{"api-key":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}'
GO



-- create a reference to the external model that will be used to create embeddings
CREATE EXTERNAL MODEL [text-embedding-3-small]
WITH (
    LOCATION = 'https://burrito-bot-ai.openai.azure.com/openai/deployments/text-embedding-3-small/embeddings?api-version=2023-05-15',
    API_FORMAT = 'Azure OpenAI',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'text-embedding-3-large',
    CREDENTIAL = [https://burrito-bot-ai.openai.azure.com]
);
GO



-- ensure stored procedure functionality enabled
EXEC sp_configure 'external rest endpoint enabled',1
RECONFIGURE;
GO



-- test generating embedding using AI_GENERATE_EMBEDDINGS referencing external model
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
