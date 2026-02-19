/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* import Raw Data
***************************************************************************
**************************************************************************/



USE [burrito-bot-db]
GO



-- enabling external rest endpoint functionality
EXEC sp_configure 'external rest endpoint enabled',1
RECONFIGURE;
GO



-- using sp_invoke_external_rest_endpoint to pull data from source
--DECLARE @ApiKey  VARCHAR(100)  = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
--DECLARE @Keyword VARCHAR(10)   = 'mexican';
--DECLARE @BaseUrl VARCHAR(100)  = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
--DECLARE @Radius VARCHAR(10)    = 20000;
--DECLARE @Latitude VARCHAR(10)  = '53.3498';
--DECLARE @Longitude VARCHAR(10) = '-6.2603';

--DECLARE @FullUrl VARCHAR(500);

--SET @FullUrl = @BaseUrl + '?location=' 
--         + @Latitude + ',' 
--         + @Longitude +
--         + '&radius=' + @Radius +
--         + '&type=restaurant' +
--         + '&keyword=' + @Keyword
--         + '&key=' + @ApiKey
--         PRINT @FullUrl

--DECLARE @ret1 INT, @response1 NVARCHAR(MAX)
--EXEC @ret1 = sp_invoke_external_rest_endpoint
--    @url = @FullUrl,
--    @response = @response1 OUTPUT;
--PRINT @response1;
--GO



-- pulling data into raw tables from CSV files
BULK INSERT [raw_data].[mexican_restaurant_reviews_Belfast]
FROM 'C:\git\aipoweredsearch\Data\Raw Data\reviews\mexican_restaurant_reviews_Belfast.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2
	);
GO



BULK INSERT [raw_data].[mexican_restaurant_reviews_Cork]
FROM 'C:\git\aipoweredsearch\Data\Raw Data\reviews\mexican_restaurant_reviews_Cork.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2
	);
GO

    

BULK INSERT [raw_data].[mexican_restaurant_reviews_Dublin]
FROM 'C:\git\aipoweredsearch\Data\Raw Data\reviews\mexican_restaurant_reviews_Dublin.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2
	);
GO



BULK INSERT [raw_data].[mexican_restaurant_reviews_Galway]
FROM 'C:\git\aipoweredsearch\Data\Raw Data\reviews\mexican_restaurant_reviews_Galway.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2
	);
GO



BULK INSERT [raw_data].[mexican_restaurant_reviews_Limerick]
FROM 'C:\git\aipoweredsearch\Data\Raw Data\reviews\mexican_restaurant_reviews_Limerick.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2
	);
GO



BULK INSERT [raw_data].[mexican_restaurant_reviews_Waterford]
FROM 'C:\git\aipoweredsearch\Data\Raw Data\reviews\mexican_restaurant_reviews_Waterford.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2
	);
GO