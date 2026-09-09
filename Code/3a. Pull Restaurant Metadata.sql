/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/burrito-bot
* Pull restaurant metadata
***************************************************************************
**************************************************************************/



USE [burrito-bot-db]
GO



-- ensure stored procedure functionality enabled
EXEC sp_configure 'external rest endpoint enabled',1
RECONFIGURE;
GO



-- setting variables for restaurants in Dublin
DECLARE @ApiKey     VARCHAR(100)    = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
DECLARE @Keyword    VARCHAR(10)     = 'mexican';
DECLARE @BaseUrl    VARCHAR(100)    = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
DECLARE @Radius     VARCHAR(10)     = 20000;
DECLARE @Latitude   VARCHAR(10)     = '53.3498';
DECLARE @Longitude  VARCHAR(10)     = '-6.2603';
DECLARE @FullUrl    VARCHAR(500);



-- construct url from variables
SET @FullUrl = @BaseUrl + '?location=' 
         + @Latitude + ',' 
         + @Longitude +
         + '&radius=' + @Radius +
         + '&type=restaurant' +
         + '&keyword=' + @Keyword
         + '&key=' + @ApiKey
         PRINT @FullUrl



-- using sp_invoke_external_rest_endpoint to pull data from source
DECLARE @ret1 INT, @response1 NVARCHAR(MAX)

EXEC @ret1 = sp_invoke_external_rest_endpoint
        @url = @FullUrl,
        @response = @response1 OUTPUT;
--SELECT @response1;



-- parsing results
SELECT
    place_id,
    name,
    rating,
    review_count,
    address
FROM OPENJSON(@response1, '$.result.results')
WITH (
    [place_id]      NVARCHAR(255)   '$.place_id',
    [name]          NVARCHAR(50)    '$.name',
    [rating]        FLOAT           '$.rating',
    [review_count]  SMALLINT        '$.user_ratings_total',
    [address]       NVARCHAR(100)   '$.vicinity'
);
GO