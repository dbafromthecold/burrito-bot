$ApiKey  = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$BaseUrl = "https://places.googleapis.com/v1/places:searchText"

$Headers = @{
    "Content-Type"     = "application/json"
    "X-Goog-Api-Key"   = $ApiKey
    "X-Goog-FieldMask" = "places.id,nextPageToken"
}


$Cities = @(
    @{ Name="Dublin";   Lat=53.3498; Lng=-6.2603 },
    @{ Name="Cork";     Lat=51.8985; Lng=-8.4756 },
    @{ Name="Limerick"; Lat=52.6638; Lng=-8.6267 },
    @{ Name="Galway";   Lat=53.2707; Lng=-9.0568 },
    @{ Name="Belfast";  Lat=54.5973; Lng=-5.9301 },
    @{ Name="Waterford"; Lat=52.2593; Lng=-7.1101 }
)

$CityName = "Waterford"
$City = $Cities | Where-Object { $_.Name -eq $CityName }
$Latitude = $City.Lat
$Longitude = $City.Lng

$Radius    = 20000       # metres

$Query     = "Mexican restaurants"
$PageSize  = 20

$AllResults    = @()
$NextPageToken = $null
$Page          = 1

do {

    Start-Sleep -Seconds 3   # required before using nextPageToken

    $Body = @{
            textQuery = $Query
            pageSize  = $PageSize
            locationBias = @{
                circle = @{
                    center = @{
                        latitude  = $Latitude
                        longitude = $Longitude
                    }
                    radius = $Radius
                }
            }
        }

    if ($NextPageToken) {
        $Body.pageToken = $NextPageToken
    }

    $JsonBody = $Body | ConvertTo-Json -Depth 5 -Compress

    Write-Host "Calling page $Page for $CityName..."

    try {
        $Response = Invoke-RestMethod `
            -Method POST `
            -Uri $BaseUrl `
            -Headers $Headers `
            -Body $JsonBody
    }
    catch {
        Write-Warning "No more pages available."
        break
    }

    if ($Response.places) {
        foreach ($Place in $Response.places) {
            $AllResults += [PSCustomObject]@{
                place_id = $Place.id
                city     = $CityName
            }
        }
    }

    $NextPageToken = $Response.nextPageToken
    $Page++

} while ($NextPageToken)

$AllResults.Count

$AllResults | Export-Csv `
    -Path "C:\temp\restaurants\mexican_placeids_$CityName.csv" `
    -NoTypeInformation -Encoding UTF8