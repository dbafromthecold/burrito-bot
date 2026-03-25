/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Vector Search Stored Procedure
***************************************************************************
**************************************************************************/



USE [burrito-bot-db];
GO



-- let's update the stored procedure to return the review data
CREATE OR ALTER PROCEDURE [dbo].[search_restaurants]
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
        --vs.distance,
        combined_reviews.reviews AS [combined_reviews]
    FROM VECTOR_SEARCH(
        TABLE      = [embeddings].[restaurant_review_embeddings] AS e,
        COLUMN     = [embeddings],
        SIMILAR_TO = @search_vector,
        METRIC     = 'cosine',
        TOP_N      = @num_results
    ) AS vs
    INNER JOIN [data].[restaurants] r ON r.id = e.restaurant_id
    INNER JOIN (SELECT
                    rv.restaurant_id as restaurant_id,
                    CONCAT(
                        d.name COLLATE Latin1_General_100_CI_AS_SC_UTF8,
                        N' is a Mexican restaurant in ',
                        d.city COLLATE Latin1_General_100_CI_AS_SC_UTF8,
                        N'. Customer reviews say:', CHAR(13) + CHAR(10),
                        STRING_AGG(
                            ' - ' + REPLACE(rv.review_text, CHAR(13) + CHAR(10), ' '),
                            CHAR(13) + CHAR(10)
                        ) WITHIN GROUP (ORDER BY rv.review_published_utc)
                    ) as reviews
                FROM [data].[reviews] rv
                INNER JOIN [data].[restaurants] d ON rv.restaurant_id = d.id
                GROUP BY rv.restaurant_id, d.name, d.city) as combined_reviews ON r.id = combined_reviews.restaurant_id
    ORDER BY vs.distance;
END
GO



-- and now give the updated stored procedure a whirl
EXEC dbo.search_restaurants
    @question = 'Good place for a casual date night?',
    @num_results= 5;
GO
