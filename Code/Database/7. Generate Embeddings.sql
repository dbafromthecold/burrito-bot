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



-- generate embeddings using external model and insert into table
-- remember, we want to incorporate meaning into the embeddings!
-- check the execution plan!
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



--let's compare the size of the main table to the size of the embeddings table
EXEC sp_spaceused 'data.restaurants';
GO

EXEC sp_spaceused 'data.reviews';
GO

EXEC sp_spaceused 'embeddings.restaurant_review_embeddings';
GO