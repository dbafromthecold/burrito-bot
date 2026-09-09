/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/burrito-bot
* Pull restaurant reviews
***************************************************************************
**************************************************************************/




USE [burrito-bot-db]
GO



-- ensure stored procedure functionality enabled
EXEC sp_configure 'external rest endpoint enabled',1
RECONFIGURE;
GO



-- declare variables
DECLARE @ApiKey     VARCHAR(100) = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
DECLARE @PlaceId    VARCHAR(50)  = 'ChIJYczaQt4PZ0gRsN10i1TxJk8';
DECLARE @FullUrl    VARCHAR(500);



-- construct url
SET @FullUrl = 'https://places.googleapis.com/v1/places/' + @PlaceId;

DECLARE @Headers NVARCHAR(MAX) =
'{"X-Goog-Api-Key":"' + @ApiKey +
'","X-Goog-FieldMask":"reviews"}';

DECLARE @ret1 INT, @response1 NVARCHAR(MAX);



-- pull review data
EXEC @ret1 = sp_invoke_external_rest_endpoint
    @url = @FullUrl,
    @headers = @Headers,
    @method = 'GET',
    @response = @response1 OUTPUT;
--SELECT @response1;



-- parse results
SELECT [review]
FROM OPENJSON(@response1, '$.result.reviews')
WITH ([review] NVARCHAR(MAX) '$.text.text');
GO