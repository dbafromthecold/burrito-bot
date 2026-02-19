


$Server = "localhost"
$Database = "burrito-bot-db"

$Query = "SELECT CAST(embeddings AS NVARCHAR(MAX)) AS Embedding
FROM [embeddings].[restaurant_review_embeddings]
ORDER BY Id"

$Rows = Invoke-SqlCmd -ServerInstance $Server -Database $Database -Query $Query -MaxCharLength 1000000

$CleanedData = @()

foreach($row in $rows){
    $CleanedDataRow = $row.Embedding
    $CleanedData += ($CleanedDataRow.Trim('[', ']')).Replace(",","`t")
}

$CleanedData | Set-Content C:\temp\embeddings.tsv 





$rows = Invoke-Sqlcmd `
    -ServerInstance $Server `
    -Database $Database `
    -Query "
SELECT
    CONCAT(
        d.name, ' is a Mexican restaurant in ', d.city, '. ',
        'Customer reviews say: ',
        STRING_AGG(
            REPLACE(
                REPLACE(rv.review_text, CHAR(13), ' '),
                CHAR(10), ' '
            ),
            ' | '
        ) WITHIN GROUP (ORDER BY rv.review_published_utc)
    ) AS metadata_text
FROM [data].[reviews] rv
INNER JOIN [data].[restaurants] d ON rv.restaurant_id = d.id
GROUP BY rv.restaurant_id, d.name, d.city;
    "

$rows | Select-Object -ExpandProperty metadata_text |
    Set-Content "C:\temp\restaurant_metadata.tsv"



##$rows |
##ForEach-Object {
##   @(
##        $_.name,
##        $_.city,
##        $_.rating,
##        $_.review_count,
##        $_.address,
##        $_.phone
 ##   ) -join "`t"
##} |
##Set-Content "C:\temp\restaurant_metadata.tsv"
