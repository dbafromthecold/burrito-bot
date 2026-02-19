/**************************************************************************
***************************************************************************
* AI-Powered Search - Andrew Pruski
* @dbafromthecold.com
* dbafromthecold@gmail.com
* https://github.com/dbafromthecold/aipoweredsearch
* Create database
***************************************************************************
**************************************************************************/



USE [master]
GO



-- ensure database doesn't already exist
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'burrito-bot-db')
	DROP DATABASE [burrito-bot-db];
GO



-- create database with separate file and filegroup for embedding data
CREATE DATABASE [burrito-bot-db]
 ON PRIMARY 
( NAME = N'burrito-bot-db',				FILENAME = N'F:\SQLData1\burrito-bot-db.mdf' ,				SIZE = 1048576KB , MAXSIZE = UNLIMITED, FILEGROWTH = 524288KB ), 
 FILEGROUP [ARCHIVE] 
( NAME = N'burrito-bot-db-archive',		FILENAME = N'F:\SQLData1\burrito-bot-db-archive.ndf' ,		SIZE = 1048576KB , MAXSIZE = UNLIMITED, FILEGROWTH = 524288KB ), 
 FILEGROUP [DATA] 
( NAME = N'burrito-bot-db-data',		FILENAME = N'F:\SQLData1\burrito-bot-db-data.ndf' ,			SIZE = 1048576KB , MAXSIZE = UNLIMITED, FILEGROWTH = 524288KB ), 
 FILEGROUP [EMBEDDINGS] 
( NAME = N'burrito-bot-db-embeddings',	FILENAME = N'F:\SQLData1\burrito-bot-db-embeddings.ndf' ,	SIZE = 1048576KB , MAXSIZE = UNLIMITED, FILEGROWTH = 524288KB ), 
 FILEGROUP [RAW_DATA] 
( NAME = N'burrito-bot-db-raw-data',	FILENAME = N'F:\SQLData1\burrito-bot-db-raw-data.ndf' ,		SIZE = 1048576KB , MAXSIZE = UNLIMITED, FILEGROWTH = 524288KB )
 LOG ON 
( NAME = N'burrito-bot-db_log',			FILENAME = N'G:\SQLTLog1\burrito-bot-db_log.ldf' ,			SIZE = 5242880KB , MAXSIZE = UNLIMITED, FILEGROWTH = 524288KB );
GO
