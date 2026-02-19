USE [master];
GO



-- enable the stored procedure
EXECUTE sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO



-- confirm 
EXECUTE sp_configure 'external rest endpoint enabled';
GO



-- get a cat fact!
DECLARE @result NVARCHAR(MAX);
EXECUTE sp_invoke_external_rest_endpoint
    @url = N'https://catfact.ninja/fact',
    @method = N'GET',
    @response = @result OUTPUT;
PRINT @result;
SELECT JSON_VALUE(@result, '$.result.fact') AS Fact;
GO



-- get some random advice!
DECLARE @result NVARCHAR(MAX);
EXEC sp_invoke_external_rest_endpoint
    @url = N'https://api.adviceslip.com/advice',
    @method = 'GET',
    @response = @result OUTPUT;
PRINT @result;
SELECT JSON_VALUE(@result, '$.result.slip.advice') AS Advice;
GO



-- get the weather!
DECLARE @result NVARCHAR(MAX);
EXEC sp_invoke_external_rest_endpoint
    @url = N'https://wttr.in/Dublin?format=j1',
    @method = 'GET',
    @response = @result OUTPUT;
PRINT @result;
GO