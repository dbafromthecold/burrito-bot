/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Create raw data tables
***************************************************************************
**************************************************************************/



USE [burrito-bot-db]
GO



-- create tables to hold raw data, separated out by location
CREATE TABLE [raw_data].[mexican_restaurant_reviews_Belfast](
	[place_id]				[nvarchar](50) NOT NULL,
	[place_name]			[nvarchar](50) NOT NULL,
	[formatted_address]		[nvarchar](100) NOT NULL,
	[latitude]				[float] NOT NULL,
	[longitude]				[float] NOT NULL,
	[place_rating]			[float] NOT NULL,
	[place_review_count]	[smallint] NOT NULL,
	[review_name]			[nvarchar](150) NOT NULL,
	[review_rating]			[tinyint] NOT NULL,
	[review_published_utc]	[nvarchar](50) NOT NULL,
	[review_relative_time]	[nvarchar](50) NOT NULL,
	[review_text]			[nvarchar](max) NOT NULL,
	[review_original_text]	[nvarchar](max) NOT NULL,
	[review_maps_uri]		[nvarchar](200) NOT NULL
) ON [RAW_DATA]
GO



CREATE TABLE [raw_data].[mexican_restaurant_reviews_Cork](
	[place_id]				[nvarchar](50) NOT NULL,
	[place_name]			[nvarchar](50) NOT NULL,
	[formatted_address]		[nvarchar](100) NOT NULL,
	[latitude]				[float] NOT NULL,
	[longitude]				[float] NOT NULL,
	[place_rating]			[float] NOT NULL,
	[place_review_count]	[smallint] NOT NULL,
	[review_name]			[nvarchar](150) NOT NULL,
	[review_rating]			[tinyint] NOT NULL,
	[review_published_utc]	[nvarchar](50) NOT NULL,
	[review_relative_time]	[nvarchar](50) NOT NULL,
	[review_text]			[nvarchar](max) NOT NULL,
	[review_original_text]	[nvarchar](max) NOT NULL,
	[review_maps_uri]		[nvarchar](200) NOT NULL
) ON [RAW_DATA]
GO



CREATE TABLE [raw_data].[mexican_restaurant_reviews_Dublin](
	[place_id]				[nvarchar](50) NOT NULL,
	[place_name]			[nvarchar](50) NOT NULL,
	[formatted_address]		[nvarchar](100) NOT NULL,
	[latitude]				[float] NOT NULL,
	[longitude]				[float] NOT NULL,
	[place_rating]			[float] NOT NULL,
	[place_review_count]	[smallint] NOT NULL,
	[review_name]			[nvarchar](150) NOT NULL,
	[review_rating]			[tinyint] NOT NULL,
	[review_published_utc]	[nvarchar](50) NOT NULL,
	[review_relative_time]	[nvarchar](50) NOT NULL,
	[review_text]			[nvarchar](max) NOT NULL,
	[review_original_text]	[nvarchar](max) NOT NULL,
	[review_maps_uri]		[nvarchar](200) NOT NULL
) ON [RAW_DATA]
GO



CREATE TABLE [raw_data].[mexican_restaurant_reviews_Galway](
	[place_id]				[nvarchar](50) NOT NULL,
	[place_name]			[nvarchar](50) NOT NULL,
	[formatted_address]		[nvarchar](100) NOT NULL,
	[latitude]				[float] NOT NULL,
	[longitude]				[float] NOT NULL,
	[place_rating]			[float] NOT NULL,
	[place_review_count]	[smallint] NOT NULL,
	[review_name]			[nvarchar](150) NOT NULL,
	[review_rating]			[tinyint] NOT NULL,
	[review_published_utc]	[nvarchar](50) NOT NULL,
	[review_relative_time]	[nvarchar](50) NOT NULL,
	[review_text]			[nvarchar](max) NOT NULL,
	[review_original_text]	[nvarchar](max) NOT NULL,
	[review_maps_uri]		[nvarchar](200) NOT NULL
) ON [RAW_DATA]
GO



CREATE TABLE [raw_data].[mexican_restaurant_reviews_Limerick](
	[place_id]				[nvarchar](50) NOT NULL,
	[place_name]			[nvarchar](50) NOT NULL,
	[formatted_address]		[nvarchar](100) NOT NULL,
	[latitude]				[float] NOT NULL,
	[longitude]				[float] NOT NULL,
	[place_rating]			[float] NOT NULL,
	[place_review_count]	[smallint] NOT NULL,
	[review_name]			[nvarchar](150) NOT NULL,
	[review_rating]			[tinyint] NOT NULL,
	[review_published_utc]	[nvarchar](50) NOT NULL,
	[review_relative_time]	[nvarchar](50) NOT NULL,
	[review_text]			[nvarchar](max) NOT NULL,
	[review_original_text]	[nvarchar](max) NOT NULL,
	[review_maps_uri]		[nvarchar](200) NOT NULL
) ON [RAW_DATA]
GO



CREATE TABLE [raw_data].[mexican_restaurant_reviews_Waterford](
	[place_id]				[nvarchar](50) NOT NULL,
	[place_name]			[nvarchar](50) NOT NULL,
	[formatted_address]		[nvarchar](100) NOT NULL,
	[latitude]				[float] NOT NULL,
	[longitude]				[float] NOT NULL,
	[place_rating]			[float] NOT NULL,
	[place_review_count]	[smallint] NOT NULL,
	[review_name]			[nvarchar](150) NOT NULL,
	[review_rating]			[tinyint] NOT NULL,
	[review_published_utc]	[nvarchar](50) NOT NULL,
	[review_relative_time]	[nvarchar](50) NOT NULL,
	[review_text]			[nvarchar](max) NOT NULL,
	[review_original_text]	[nvarchar](max) NOT NULL,
	[review_maps_uri]		[nvarchar](200) NOT NULL
) ON [RAW_DATA]
GO