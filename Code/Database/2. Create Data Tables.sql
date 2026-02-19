/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Create database tables
***************************************************************************
**************************************************************************/



USE [burrito-bot-db]
GO



-- create schemas, including separate schema for embedding data
CREATE SCHEMA [archive];
GO
CREATE SCHEMA [data];
GO
CREATE SCHEMA [embeddings];
GO
CREATE SCHEMA [raw_data];
GO



-- create main table to hold data
CREATE TABLE [data].[restaurants](
	[id]			[int] IDENTITY(1,1) CONSTRAINT [pk_restaurants] PRIMARY KEY CLUSTERED NOT NULL,
	[place_id]		[nvarchar](255) NOT NULL,
	[name]			[nvarchar](50) NOT NULL,
	[city]			[nvarchar](50) NOT NULL,
	[rating]		[float] NOT NULL,
	[review_count]	[smallint] NOT NULL,
	[address]		[nvarchar](100) NOT NULL,
	[phone]			[nvarchar](50) NULL,
	[url]			[nvarchar](200) NOT NULL,
) ON [DATA];
GO


-- create table to hold review data
CREATE TABLE [data].[reviews](
	review_id				INT IDENTITY(1,1) CONSTRAINT [pk_reviews] PRIMARY KEY CLUSTERED NOT NULL,
	restaurant_id			INT,
	place_id				NVARCHAR(50),
	review_name				NVARCHAR(150),
	review_rating			TINYINT,
	review_published_utc	NVARCHAR(50),
	review_text				NVARCHAR(MAX))
	GO

ALTER TABLE [data].[reviews] WITH CHECK ADD  CONSTRAINT [FK_data_reviews] FOREIGN KEY([restaurant_id])
REFERENCES [data].[restaurants] ([id]);
GO

ALTER TABLE [data].[reviews] CHECK CONSTRAINT [FK_data_reviews];
GO



-- create table to hold embedding data, FK reference to main table
-- size of vector column is dictated by model referenced
CREATE TABLE [embeddings].[restaurant_review_embeddings](
	[id]			[int] IDENTITY(1,1) NOT NULL,
	[restaurant_id] [int] NULL,
	[embeddings]	[vector](1536, float32) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [EMBEDDINGS]
) ON [EMBEDDINGS];
GO

ALTER TABLE [embeddings].[restaurant_review_embeddings]  WITH CHECK ADD  CONSTRAINT [FK_restaurant_review_embeddings_restaurants] FOREIGN KEY([restaurant_id])
REFERENCES [data].[restaurants] ([id]);
GO

ALTER TABLE [embeddings].[restaurant_review_embeddings] CHECK CONSTRAINT [FK_restaurant_review_embeddings_restaurants];
GO
