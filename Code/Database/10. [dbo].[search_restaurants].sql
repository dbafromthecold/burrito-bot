USE [burrito-bot-db]
GO

/****** Object:  StoredProcedure [dbo].[search_restaurants]    Script Date: 2/19/2026 10:37:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE    PROCEDURE [dbo].[search_restaurants]
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
        vs.distance,
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
                        d.name, ' is a Mexican restaurant in ', d.city, '. ',
                        'Customer reviews say:', CHAR(13) + CHAR(10),
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


