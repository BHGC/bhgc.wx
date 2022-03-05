bhgc.wx
=======

Version: 0.3.0-9001 [2022-03-05]

NEW FEATURES:

 * Add more sites.

 * Add `inst/bin/bhgc-wx` script.
 

Version: 0.3.0 [2020-02-29]

SIGNIFICANT CHANGES:

 * `read_noaa()` now return GPS coordinates as three separate columns
   'latitude', 'longitude', and 'altitude'.
   
NEW FEATURES:

 * Add `save_noaa()` to save a weather forecast to an RDS file.

 * Add `update_noaa()` to save weather forcast to database if updated.

 * `timezone(new)` returns current time zone invisibly if a new one is set.
 
 * Argument 'days' for `ggplot_noaa_{wind_direction,surface_wind}()` can now
   specify number of days forward by specifying a single scalar.



Version: 0.2.0 [2020-02-16]

NEW FEATURES:

 * Added support for 'site' URL query.
 
BUG FIX:

 * Now `make deploy` can deploy with the package on GitHub.
 

Version: 0.1.3-9000 [2019-12-13]

 * Turned into an R package.


Version 0.1.3 (2019-05-24)

NEW FEATURES:

 * Add support for URL queries, i.e. `site_idx = 4`.


Version 0.1.2 (2018-10-31)

NEW FEATURES:

 * Now x-axis label clutter is avoided by presenting less details when the
   window/screen is narrow and too many days are displayed.


Version 0.1.1 (2018-10-16)

BUG FIXES:

 * NOAA renamed field 'temperature (heat index)' to 'temperature (hourly)'.
 

Version 0.1.0 (2018-09-08)

NEW FEATURES:

 * Deployed app on shinyapps.io.



