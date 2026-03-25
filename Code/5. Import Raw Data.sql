/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/burrito-bot
* import Raw Data
***************************************************************************
**************************************************************************/



USE [burrito-bot-db]
GO



-- pulling data into raw tables from CSV files
BULK INSERT [raw_data].[mexican_restaurant_reviews_Belfast]
FROM 'C:\git\burrito-bot\Data\Raw Data\reviews\mexican_restaurant_reviews_Belfast.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
	);
GO



BULK INSERT [raw_data].[mexican_restaurant_reviews_Cork]
FROM 'C:\git\burrito-bot\Data\Raw Data\reviews\mexican_restaurant_reviews_Cork.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
	);
GO

    

BULK INSERT [raw_data].[mexican_restaurant_reviews_Dublin]
FROM 'C:\git\burrito-bot\Data\Raw Data\reviews\mexican_restaurant_reviews_Dublin.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
	);
GO



BULK INSERT [raw_data].[mexican_restaurant_reviews_Galway]
FROM 'C:\git\burrito-bot\Data\Raw Data\reviews\mexican_restaurant_reviews_Galway.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
	);
GO



BULK INSERT [raw_data].[mexican_restaurant_reviews_Limerick]
FROM 'C:\git\burrito-bot\Data\Raw Data\reviews\mexican_restaurant_reviews_Limerick.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
	);
GO



BULK INSERT [raw_data].[mexican_restaurant_reviews_Waterford]
FROM 'C:\git\burrito-bot\Data\Raw Data\reviews\mexican_restaurant_reviews_Waterford.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
	);
GO