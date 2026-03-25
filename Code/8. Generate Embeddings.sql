/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Generate Embeddings
***************************************************************************
**************************************************************************/




USE [burrito-bot-db];
GO



-- check the data
SELECT * FROM [data].[restaurants];
GO
SELECT * FROM [data].[reviews];
GO



-- let's have a look at chunking the data
SELECT rv.review_id, c.chunk
FROM [data].[reviews] rv
CROSS APPLY
    AI_GENERATE_CHUNKS (
        SOURCE = review_text, -- text to chunk
        CHUNK_TYPE = FIXED,   -- method to chunk 
        CHUNK_SIZE = 100,     -- character count size of each chunk
        OVERLAP = 10          -- percentage of preceeding text to be included
    ) AS c;
GO



-- generate embeddings using external model and insert into table
-- remember, we want to incorporate meaning into the embeddings!
INSERT INTO [embeddings].[restaurant_review_embeddings] (restaurant_id, embeddings)
SELECT
    rv.restaurant_id,
    AI_GENERATE_EMBEDDINGS(
        CONCAT(
            d.name, ' is a Mexican restaurant in ', d.city, '. ',
            'Customer reviews say:', CHAR(13) + CHAR(10),
            STRING_AGG(
                ' - ' + REPLACE(rv.review_text, CHAR(13) + CHAR(10), ' '),
                CHAR(13) + CHAR(10)
            ) WITHIN GROUP (ORDER BY rv.review_published_utc)
        )
        USE MODEL [text-embedding-3-small]
    )
FROM [data].[reviews] rv
INNER JOIN [data].[restaurants] d ON rv.restaurant_id = d.id
GROUP BY rv.restaurant_id, d.name, d.city;



-- let's have a look at the data!
SELECT *
FROM [data].[restaurants] r
INNER JOIN [embeddings].[restaurant_review_embeddings] e ON r.id = e.restaurant_id;
GO



-- let's check out the embeddings column
SELECT CAST([embeddings] AS JSON) 
FROM [embeddings].[restaurant_review_embeddings] 
WHERE id = 1;
GO