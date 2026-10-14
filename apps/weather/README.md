# Weather

Today's weather for a city you choose: the temperature now with an icon, the high and low, and the chance of rain.

- **B** updates it (over your unidex's WiFi, set up on the website's Setup page).
- **Hold B** picks the city: UK cities from London to Belfast, plus Dublin, Paris, Berlin, Madrid, New York and
  Tokyo.

The last forecast stays on screen, with when it was fetched, so it's still useful away from WiFi.

**What it connects to:** `api.open-meteo.com`, over HTTPS, sending only the latitude and longitude of the city you
picked. [Open-Meteo](https://open-meteo.com) is free and needs no account or key. Nothing else is sent.
