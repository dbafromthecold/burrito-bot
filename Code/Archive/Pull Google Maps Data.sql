USE [burrito-bot-db];
GO

DECLARE @ApiKey  VARCHAR(100)  = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
DECLARE @Keyword VARCHAR(10)   = 'mexican';
DECLARE @BaseUrl VARCHAR(100)  = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
DECLARE @Radius VARCHAR(10)    = 20000;
DECLARE @Latitude VARCHAR(10)  = '53.3498';
DECLARE @Longitude VARCHAR(10) = '-6.2603';

DECLARE @FullUrl VARCHAR(500);

SET @FullUrl = @BaseUrl + '?location=' 
         + @Latitude + ',' 
         + @Longitude +
         + '&radius=' + @Radius +
         + '&type=restaurant' +
         + '&keyword=' + @Keyword
         + '&key=' + @ApiKey
         PRINT @FullUrl

DECLARE @ret1 INT, @response1 NVARCHAR(MAX)
EXEC @ret1 = sp_invoke_external_rest_endpoint
    @url = @FullUrl,
    @response = @response1 OUTPUT;
PRINT @response1