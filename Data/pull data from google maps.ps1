


$ApiKey  = " XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$Keyword = "mexican"
$BaseUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
$Radius  = 20000



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



$Results   = @()
$NextPageToken = $null
$Page          = 1

do {
    if ($NextPageToken) {
        Start-Sleep -Seconds 2   # REQUIRED by Google
        $Url = "$BaseUrl" + "?pagetoken=$NextPageToken&key=$ApiKey"
    }
    else {
        $Url = "$BaseUrl" + "?location=$Latitude,$Longitude" +
               "&radius=$Radius" +
               "&type=restaurant" +
               "&keyword=$Keyword" +
               "&key=$ApiKey"
    }

    Write-Host "Calling page $Page"
    $Response = Invoke-RestMethod -Method GET -Uri $Url

    if ($Response.status -ne "OK") {
        Write-Error "Google API returned status: $($Response.status)"
        break
    }

    $Results += $Response.results
    $NextPageToken = $Response.next_page_token
    $Page++

} while ($NextPageToken)



$Results.results.count



$AllResults = @()
foreach ($Place in $Results) {
        $AllResults += [PSCustomObject]@{
            place_id           = $Place.place_id
            name               = $Place.name
            rating             = $Place.rating
            review_count       = $Place.user_ratings_total
            price_level        = $Place.price_level
            address            = $Place.vicinity
            phone_number      = $Place.international_phone_number
            latitude           = $Place.geometry.location.lat
            longitude          = $Place.geometry.location.lng
            business_status    = $Place.business_status
        }
    }


$AllResults

$AllResults | Export-Csv -Path "C:\temp\restaurants\mexican_restaurants_$CityName.csv" -NoTypeInformation -Encoding UTF8

