$CityName = "Waterford"


$ApiKey = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$restaurants = Import-Csv "C:\temp\restaurants\mexican_restaurants_placeids_$CityName.csv"

$PlaceIDs= $restaurants.place_id

$Results   = @()

foreach($PlaceId in $PlaceIDs){

$DetailsUrl = "https://places.googleapis.com/v1/places/$PlaceId"

    $Headers = @{
        "X-Goog-Api-Key"    = $ApiKey
        "X-Goog-FieldMask"  = "id,displayName,rating,userRatingCount,formattedAddress,location,reviews"
    }

    $Response = Invoke-RestMethod -Method GET -Uri $DetailsUrl -Headers $Headers
    $Results += $Response

}


$Results.Count



$ReviewRows = foreach ($p in $Results) {

    # If a place has no reviews, skip it (or output a row with null review fields—your choice)
    if (-not $p.reviews) { continue }

    foreach ($r in $p.reviews) {
        [PSCustomObject]@{
            place_id            = $p.id
            place_name          = $p.displayName.text
            formatted_address   = $p.formattedAddress
            latitude            = $p.location.latitude
            longitude           = $p.location.longitude
            place_rating        = $p.rating
            place_review_count  = $p.userRatingCount

            review_name         = $r.name
            review_rating       = $r.rating
            review_published_utc= $r.publishTime
            review_relative_time= $r.relativePublishTimeDescription
            review_text         = $r.text.text   # sometimes empty
            review_original_text= $r.originalText.text
            review_maps_uri     = $r.googleMapsUri
        }
    }
}


$ReviewRows | Export-Csv "C:\temp\restaurants\mexican_restaurant_reviews_$CityName.csv" -NoTypeInformation -Encoding UTF8