/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Import data to main tables
***************************************************************************
**************************************************************************/



USE [burrito-bot-db];
GO



-- inserting raw data into main table, adding location URL
INSERT INTO [data].[restaurants]
           ([place_id],
            [name]
           ,[city]
           ,[rating]
           ,[review_count]
           ,[address]
           ,[phone]
           ,[url])
SELECT DISTINCT
        place_id
        ,place_name 
        ,'Belfast'
        ,place_rating
        ,place_review_count
        ,formatted_address
        ,NULL
        ,'https://www.google.com/maps/place/?q=place_id:' + [place_id]
FROM [raw_data].[mexican_restaurant_reviews_Belfast];
GO



INSERT INTO [data].[restaurants]
           ([place_id],
            [name]
           ,[city]
           ,[rating]
           ,[review_count]
           ,[address]
           ,[phone]
           ,[url])
SELECT DISTINCT
        place_id
        ,place_name 
        ,'Cork'
        ,place_rating
        ,place_review_count
        ,formatted_address
        ,NULL
        ,'https://www.google.com/maps/place/?q=place_id:' + [place_id]
FROM [raw_data].[mexican_restaurant_reviews_Cork];
GO



INSERT INTO [data].[restaurants]
           ([place_id],
            [name]
           ,[city]
           ,[rating]
           ,[review_count]
           ,[address]
           ,[phone]
           ,[url])
SELECT DISTINCT
        place_id
        ,place_name 
        ,'Dublin'
        ,place_rating
        ,place_review_count
        ,formatted_address
        ,NULL
        ,'https://www.google.com/maps/place/?q=place_id:' + [place_id]
FROM [raw_data].[mexican_restaurant_reviews_Dublin];
GO



INSERT INTO [data].[restaurants]
           ([place_id],
            [name]
           ,[city]
           ,[rating]
           ,[review_count]
           ,[address]
           ,[phone]
           ,[url])
SELECT DISTINCT
        place_id
        ,place_name 
        ,'Galway'
        ,place_rating
        ,place_review_count
        ,formatted_address
        ,NULL
        ,'https://www.google.com/maps/place/?q=place_id:' + [place_id]
FROM [raw_data].[mexican_restaurant_reviews_Galway];
GO



INSERT INTO [data].[restaurants]
           ([place_id],
            [name]
           ,[city]
           ,[rating]
           ,[review_count]
           ,[address]
           ,[phone]
           ,[url])
SELECT DISTINCT
        place_id
        ,place_name 
        ,'Limerick'
        ,place_rating
        ,place_review_count
        ,formatted_address
        ,NULL
        ,'https://www.google.com/maps/place/?q=place_id:' + [place_id]
FROM [raw_data].[mexican_restaurant_reviews_Limerick];
GO



INSERT INTO [data].[restaurants]
           ([place_id],
            [name]
           ,[city]
           ,[rating]
           ,[review_count]
           ,[address]
           ,[phone]
           ,[url])
SELECT DISTINCT
        place_id
        ,place_name 
        ,'Waterford'
        ,place_rating
        ,place_review_count
        ,formatted_address
        ,NULL
        ,'https://www.google.com/maps/place/?q=place_id:' + [place_id]
FROM [raw_data].[mexican_restaurant_reviews_Waterford];
GO



INSERT INTO [data].[reviews]
           ([restaurant_id]
           ,[place_id]
           ,[review_name]
           ,[review_rating]
           ,[review_published_UTC]
           ,[review_text])
SELECT 
           r.id
           ,d.place_id
           ,d.review_name
           ,d.review_rating
           ,d.review_published_UTC
           ,d.review_text
FROM [raw_data].[mexican_restaurant_reviews_Belfast] AS d
INNER JOIN [data].[restaurants] r ON d.place_id = r.place_id
WHERE r.City = 'Belfast'
GO



INSERT INTO [data].[reviews]
           ([restaurant_id]
           ,[place_id]
           ,[review_name]
           ,[review_rating]
           ,[review_published_UTC]
           ,[review_text])
SELECT 
           r.id
           ,d.place_id
           ,d.review_name
           ,d.review_rating
           ,d.review_published_UTC
           ,d.review_text
FROM [raw_data].[mexican_restaurant_reviews_Cork] AS d
INNER JOIN [data].[restaurants] r ON d.place_id = r.place_id
WHERE r.City = 'Cork'
GO



INSERT INTO [data].[reviews]
           ([restaurant_id]
           ,[place_id]
           ,[review_name]
           ,[review_rating]
           ,[review_published_UTC]
           ,[review_text])
SELECT 
           r.id
           ,d.place_id
           ,d.review_name
           ,d.review_rating
           ,d.review_published_UTC
           ,d.review_text
FROM [raw_data].[mexican_restaurant_reviews_Dublin] AS d
INNER JOIN [data].[restaurants] r ON d.place_id = r.place_id
WHERE r.City = 'Dublin'
GO



INSERT INTO [data].[reviews]
           ([restaurant_id]
           ,[place_id]
           ,[review_name]
           ,[review_rating]
           ,[review_published_UTC]
           ,[review_text])
SELECT 
           r.id
           ,d.place_id
           ,d.review_name
           ,d.review_rating
           ,d.review_published_UTC
           ,d.review_text
FROM [raw_data].[mexican_restaurant_reviews_Galway] AS d
INNER JOIN [data].[restaurants] r ON d.place_id = r.place_id
WHERE r.City = 'Galway'
GO



INSERT INTO [data].[reviews]
           ([restaurant_id]
           ,[place_id]
           ,[review_name]
           ,[review_rating]
           ,[review_published_UTC]
           ,[review_text])
SELECT 
           r.id
           ,d.place_id
           ,d.review_name
           ,d.review_rating
           ,d.review_published_UTC
           ,d.review_text
FROM [raw_data].[mexican_restaurant_reviews_Limerick] AS d
INNER JOIN [data].[restaurants] r ON d.place_id = r.place_id
WHERE r.City = 'Limerick'
GO



INSERT INTO [data].[reviews]
           ([restaurant_id]
           ,[place_id]
           ,[review_name]
           ,[review_rating]
           ,[review_published_UTC]
           ,[review_text])
SELECT 
           r.id
           ,d.place_id
           ,d.review_name
           ,d.review_rating
           ,d.review_published_UTC
           ,d.review_text
FROM [raw_data].[mexican_restaurant_reviews_Waterford] AS d
INNER JOIN [data].[restaurants] r ON d.place_id = r.place_id
WHERE r.City = 'Waterford'
GO