# Pull Mexican restaurants in Dublin from OpenStreetMap via Overpass API
# Requirements: PowerShell 5+ (Invoke-RestMethod)

$overpassUrl = "https://overpass-api.de/api/interpreter"

# Overpass QL:
# - Find the administrative area named "Dublin"
# - Return amenities tagged as restaurant where cuisine contains "mexican" (case-insensitive)
# - Include nodes/ways/relations and output center points for ways/relations
$query = @'
[out:json][timeout:60];
area["name"="Dublin"]["boundary"="administrative"]->.searchArea;
(
  node["amenity"="restaurant"]["cuisine"~"mexican",i](area.searchArea);
  way["amenity"="restaurant"]["cuisine"~"mexican",i](area.searchArea);
  relation["amenity"="restaurant"]["cuisine"~"mexican",i](area.searchArea);
);
out center tags;
'@

# POST as application/x-www-form-urlencoded
$body = "data=" + [System.Uri]::EscapeDataString($query)

$response = Invoke-RestMethod -Method Post -Uri $overpassUrl -ContentType "application/x-www-form-urlencoded" -Body $body

# Convert Overpass elements into a clean object list
$results = foreach ($el in $response.elements) {
  $tags = $el.tags

  $lat = $el.lat
  $lon = $el.lon
  if (-not $lat -and $el.center) { $lat = $el.center.lat }
  if (-not $lon -and $el.center) { $lon = $el.center.lon }

  [pscustomobject]@{
    Name         = $tags.name
    Cuisine      = $tags.cuisine
    Amenity      = $tags.amenity
    Latitude     = $lat
    Longitude    = $lon
    Website      = $tags.website
    Phone        = $tags.phone
    OpeningHours = $tags.opening_hours
    Address      = @(
      $tags.'addr:housenumber'
      $tags.'addr:street'
      $tags.'addr:suburb'
      $tags.'addr:city'
      $tags.'addr:postcode'
    ) -ne $null -join ", "
    OsmType      = $el.type
    OsmId        = $el.id
  }
}

# Show results (filter out blanks, sort)
$results |
  Where-Object { $_.Name } |
  Sort-Object Name |
  Format-Table -AutoSize