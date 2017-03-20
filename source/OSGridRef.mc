using Toybox.Math;
using Toybox.System;

class OSGridRef extends GridRef
{
    // Constants
     var WGS84_AXIS = 6378137.0d;
     var WGS84_ECCENTRIC = 0.00669438037928458d;
     var OSGB_AXIS = 6377563.396d;
     var OSGB_ECCENTRIC = 0.0066705397616d;
    // Helmert transform parms:  https://en.wikipedia.org/wiki/Helmert_transformation
    var Helmert= {
        "xp" => -446.448d,
        "yp" =>  125.157d,
        "zp" =>  -542.06d,
        "xr" => -0.1502d,
        "yr" => -0.247d,
        "zr" => -0.8421d,
        "s" => 20.4894d,
        "h" => 1.0d
    };
    var valid = false;
    var alpha = ["A","B","C","D","E","F","G","H","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];

  // Create grid ref from WSG84 lat /long
    function initialize(lat, lon, p )
    {
        // Check we have a valid UK lat & long
        if (lon == null or lat == null
            or lon.toNumber() < -10 or lon.toNumber() > 4
            or lat.toNumber() < 49.5 or lat.toNumber() > 62) {
            valid = false;
            return;
        }
        //
        // Initialise superclass
        GridRef.initialize(lat, lon, p );
        //
        // Looks good so far so convert to OSGB36 Eastings & Northings
        valid = true;
        var numeric_grid_ref = OSBG36_latlon_to_numeric_gridref(  WSG84_to_OSGB36(lat,lon) );
        if (numeric_grid_ref[0] < 0 or numeric_grid_ref[1] < 0)
        {
            valid = false;
        }
        //
        // Got a valid numberic Eastings and Northings GR so convert to text grid ref
        else
        {
           var text_grid_ref = toOSGridRef(numeric_grid_ref[0], numeric_grid_ref[1], precision, valid);
           text = text_grid_ref[0];
           easting = text_grid_ref[1];
           northing = text_grid_ref[2];
           valid = text_grid_ref[3];
        }
    }

    function getGR () {
        return [text, easting , northing, valid];
    }

    function getGR_as_string () {
        return text + easting + northing;
    }

    //  Convert numeric Easting and Northing to a Grid Ref
    //   - Based on http://www.jstott.me.uk/jscoord/  -  toSixFigureString()
    //  Returns 4 element array: [t,e,n,valid] -  text, easting, northing, valid
    function toOSGridRef(east, north, precision, valid)
    {
          var t = "";
          var e = "";
          var n = "";
    //System.println("numeric grid "  + east.toString() + "," + north.toString() );
          //
          // Easting & Northing must be >= 0
          if (valid == true && east >= 0 && north >= 0)
          {
            var hundredkmE = floor(east.toDouble() / 100000);
            var hundredkmN = floor(north.toDouble() / 100000);
            var firstLetter = "";
            if (hundredkmN < 5) {
              if (hundredkmE < 5) {
                firstLetter = "S";
              } else {
                firstLetter = "T";
              }
            } else if (hundredkmN < 10)
            {
              if (hundredkmE < 5) {
                firstLetter = "N";
              } else {
                firstLetter = "O";
              }
            } else {
              firstLetter = "H";
            }

            var secondLetter = "";
            var index =  ((4 - (hundredkmN % 5)) * 5) + (hundredkmE % 5);
            //System.println("index: " + index );
            if (index >= 0 && index < alpha.size() )
            {
              secondLetter = alpha[index.toNumber()];
              var format_string = "%0" + precision/2 + "u"; // zero fill format
              var precision_modifier = 1; // Default to 10 figure grid ref
              if (precision == 6)   // For 6 figure grid ref drop last 2 digits
              {
                 precision_modifier = 100;
              }
              else if (precision == 8)  // For 8 figure grid ref drop last digit
              {
                 precision_modifier = 10;
              }
              e = ((east - (100000 * hundredkmE)) / precision_modifier).format(format_string);
              n = ((north - (100000 * hundredkmN)) / precision_modifier).format(format_string);
              t = (firstLetter+secondLetter);
              valid = true;
            }
            else {
                valid = false;
            }
        }

        if (valid == false) {
            t = "Outside UK?";
            e = "????";
            n = "????";
        }
        return [t,e,n,valid]; // text, easting, northing, valid
    }


    function WSG84_to_OSGB36(lat,lon)
    {
         var phip = lat * deg2rad;
         var lambdap = lon * deg2rad;
         var OSGB36_coords = transform_datum(phip, lambdap, WGS84_AXIS, WGS84_ECCENTRIC, OSGB_AXIS, OSGB_ECCENTRIC);
         return OSGB36_coords ;
    }
    //  http://www.dorcus.co.uk/carabus/ll_ngr.html
    // Convert lat / lon to eastings and northings
    //   - Input: 2 element array: [lat,lon]
    //   - Return: 2 element array: [east,north]
    function OSBG36_latlon_to_numeric_gridref(OSGB36_coords)
    {
        var lat = OSGB36_coords[0];
        var lon = OSGB36_coords[1];

        var phi = lat * deg2rad;      // convert latitude to radians
        var lam = lon * deg2rad;   // convert longitude to radians
        var a = 6377563.396d;       // OSGB semi-major axis
        var b = 6356256.91d;        // OSGB semi-minor axis
        var e0 = 400000;           // OSGB easting of false origin
        var n0 = -100000;          // OSGB northing of false origin
        var f0 = 0.9996012717d;     // OSGB scale factor on central meridian
        var e2 = 0.0066705397616d;  // OSGB eccentricity squared
        var lam0 = -0.034906585039886591d;  // OSGB false east
        var phi0 = 0.85521133347722145d;    // OSGB false north
        var af0 = a * f0;
        var bf0 = b * f0;
        // easting
        var slat2 = Math.sin(phi) * Math.sin(phi);
        var nu = af0 / (Math.sqrt(1 - (e2 * (slat2))));
        var rho = (nu * (1 - e2)) / (1 - (e2 * slat2));
        var eta2 = (nu / rho) - 1;
        var p = lam - lam0;
        var IV = nu * Math.cos(phi);
        var clat3 = Math.pow(Math.cos(phi),3);
        var tlat2 = Math.tan(phi) * Math.tan(phi);
        var V = (nu / 6) * clat3 * ((nu / rho) - tlat2);
        var clat5 = Math.pow(Math.cos(phi), 5);
        var tlat4 = Math.pow(Math.tan(phi), 4);
        var VI = (nu / 120) * clat5 * ((5 - (18 * tlat2)) + tlat4 + (14 * eta2) - (58 * tlat2 * eta2));
        var east = floor(e0 + (p * IV) + (Math.pow(p, 3) * V) + (Math.pow(p, 5) * VI));
        // northing
        var n = (af0 - bf0) / (af0 + bf0);
        var M = Marc(bf0, n, phi0, phi);
        var I = M + (n0);
        var II = (nu / 2) * Math.sin(phi) * Math.cos(phi);
        var III = ((nu / 24) * Math.sin(phi) * Math.pow(Math.cos(phi), 3)) * (5 - Math.pow(Math.tan(phi), 2) + (9 * eta2));
        var IIIA = ((nu / 720) * Math.sin(phi) * clat5) * (61 - (58 * tlat2) + tlat4);
        var north = floor(I + ((p * p) * II) + (Math.pow(p, 4) * III) + (Math.pow(p, 6) * IIIA));
    //System.println("to numeric grid "  + east.toString() + "," + north.toString() );
        return [east,north];

    }
}
