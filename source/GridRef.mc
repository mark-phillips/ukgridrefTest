using Toybox.Math;
using Toybox.System;

class GridRef
{
    var valid = false;
    var text = "Unknown location";       // Grid ref square - e.g. SU
    var easting = "????";    // Grid ref easting
    var northing = "????";   // Grid ref northing
    var precision = 10;  // Grid ref precision - 6 or 10
    var latitude = 0.0d;
    var longitude = 0.0d;
    var deg2rad = Math.PI / 180.0d;
    var rad2deg = 180.0d / Math.PI;

    // Create grid ref from WSG84 lat /long
    function initialize(lat, lon, p )
    {
        if (lat == null or lon == null) {
            valid = false;
            return;
        }
        latitude = lat.toDouble();
        longitude = lon.toDouble();
        if (p != 6 and p != 8 and p != 10)
        {
          System.println("Incorrect precision value (" + p + ")- must be one of: 6, 8 or 10.  Default of 10 will be used" );
          p = 10;
        }
        precision = p;
    }

    //function transform_datum(lat, lon, a, e, h, a2, e2, xp, yp, zp, xr, yr, zr, s)
    function transform_datum(lat, lon, a, e, a2, e2)
    {
        // convert to cartesian; lat, lon are radians
        var sf = Helmert["s"] * 0.000001;
        var v = a / (Math.sqrt(1 - (e *(Math.sin(lat) * Math.sin(lat)))));
        var x = (v + Helmert["h"]) * Math.cos(lat) * Math.cos(lon);
        var y = (v + Helmert["h"]) * Math.cos(lat) * Math.sin(lon);
        var z = ((1 - e) * v + Helmert["h"]) * Math.sin(lat);
        // transform cartesian
        var xrot = (Helmert["xr"] / 3600) * deg2rad;
        var yrot = (Helmert["yr"] / 3600) * deg2rad;
        var zrot = (Helmert["zr"] / 3600) * deg2rad;
        var hx = x + (x * sf) - (y * zrot) + (z * yrot) + Helmert["xp"];
        var hy = (x * zrot) + y + (y * sf) - (z * xrot) + Helmert["yp"];
        var hz = (-1 * x * yrot) + (y * xrot) + z + (z * sf) + Helmert["zp"];
        // Convert back to lat, lon
        lon = Math.atan(hy / hx);
        var p = Math.sqrt((hx * hx) + (hy * hy));
        lat = Math.atan(hz / (p * (1 - e2)));
        v = a2 / (Math.sqrt(1 - e2 * (Math.sin(lat) * Math.sin(lat))));
        var errvalue = 1.0;
        var lat0 = 0;
        while (errvalue > 0.001)
        {
          lat0 = Math.atan((hz + e2 * v * Math.sin(lat)) / p);
          errvalue = abs(lat0 - lat);
          lat = lat0;
        }
        var h = p / Math.cos(lat) - v;
        lat = lat* rad2deg;
        lon = lon * rad2deg;

        return [lat,lon];
    }

    function Marc(bf0, n, phi0, phi)
    {
        var Marc = bf0 * (((1 + n + ((5 / 4) * (n * n)) + ((5 / 4) * (n * n * n))) * (phi - phi0))
         - (((3 * n) + (3 * (n * n)) + ((21 / 8) * (n * n * n))) * (Math.sin(phi - phi0)) * (Math.cos(phi + phi0)))
         + ((((15 / 8) * (n * n)) + ((15 / 8) * (n * n * n))) * (Math.sin(2 * (phi - phi0))) * (Math.cos(2 * (phi + phi0))))
         - (((35 / 24) * (n * n * n)) * (Math.sin(3 * (phi - phi0))) * (Math.cos(3 * (phi + phi0)))));
        return(Marc);
    }

    function floor(x)
    {
        return x.toLong();
    }

    function abs(n)
    {
        return n >=0 ? n : -n;
    }
}