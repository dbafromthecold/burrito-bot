CREATE OR ALTER PROCEDURE dbo.GenerateAndStoreEmbeddings
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @apiKey NVARCHAR(100) = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
    DECLARE @deployment NVARCHAR(100) = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
    DECLARE @endpoint NVARCHAR(200) = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' + @deployment + 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

    DECLARE @name NVARCHAR(255),
            @city NVARCHAR(255),
            @rating FLOAT,
            @review_count INT,
            @address NVARCHAR(500),
            @phone NVARCHAR(50),
            @url NVARCHAR(1000),
            @description NVARCHAR(MAX),
            @body NVARCHAR(MAX),
            @headers NVARCHAR(MAX),
            @response NVARCHAR(MAX),
            @embeddingRaw NVARCHAR(MAX),
            @embeddingBinary VECTOR(1536);

    DECLARE row_cursor CURSOR FOR
        SELECT name, city, rating, review_count, address, phone, url
        FROM dbo.dublin_burrito_restaurants;

    OPEN row_cursor;
    FETCH NEXT FROM row_cursor INTO @name, @city, @rating, @review_count, @address, @phone, @url;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Construct description text
        SET @description = @name + ' at ' + @address + ' in ' + @city +
            '. Rating: ' + CAST(@rating AS NVARCHAR) + ' stars. Based on ' + CAST(@review_count AS NVARCHAR) + ' reviews.';

        -- Create request body (escaped double quotes)
        SET @body = N'{"input": ["' + REPLACE(@description, '"', '\"') + '"], "model": "' + @deployment + '"}';

        -- Headers must be plain ASCII, single line
        SET @headers = N'{"api-key":"' + @apiKey + '","Content-Type":"application/json"}';

        -- Call Azure OpenAI embedding endpoint
        EXEC sp_invoke_external_rest_endpoint
            @url = @endpoint,
            @method = 'POST',
            @headers = @headers,
            @payload = @body,
            @response = @response OUTPUT;

       -- PRINT '=== RAW RESPONSE ===';
      --  PRINT @response;

        -- Parse embedding array correctly
        SET @embeddingRaw = JSON_QUERY(@response, '$.result.data[0].embedding');
        SET @embeddingBinary = CAST(@embeddingRaw AS VECTOR(1536));

        -- Insert into target table
        INSERT INTO dbo.burrito_embeddings (
            name, city, rating, review_count, address, phone, url, description, embedding
        )
        VALUES (
            @name, @city, @rating, @review_count, @address, @phone, @url, @description, @embeddingBinary
        );

        -- Next row
        FETCH NEXT FROM row_cursor INTO @name, @city, @rating, @review_count, @address, @phone, @url;
    END

    CLOSE row_cursor;
    DEALLOCATE row_cursor;
END;
