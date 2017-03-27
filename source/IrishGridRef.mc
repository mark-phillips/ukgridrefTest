using Toybox.Math;
using Toybox.System;

class IrishGridRef extends GridRef
{
    // Constants
    var WGS84_AXIS = 6378137.0d;
    var WGS84_ECCENTRIC = 0.00669438037928458d;
    var MOD_AIRY_AXIS = 6377340.189d;
    var MOD_AIRY_ECCENTRIC = 0.0066705397616d;
    // Helmert transform parms:  https://en.wikipedia.org/wiki/Helmert_transformation
    var Helmert= {
        "xp" => -482.53d,
        "yp" =>  130.596d,
        "zp" =>  -564.557d,
        "xr" => 1.042d,
        "yr" => 0.214d,
        "zr" => 0.631d,
        "s" => -8.15d,
        "h" => 1
    };
    var valid = false;
    var alpha = ["A","B","C","D","E","F","G","H","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];

  // Create grid ref from WSG84 lat /long
    function initialize(lat, lon, p )
    {
        //
        // Initialise superclass
        GridRef.initialize(lat, lon, p );

        // Check we have a valid lat & long
        if (lon == null or lat == null
            or lat.toFloat() < 51.2 or lat.toFloat() > 55.8
            or lon.toFloat() < -11.1 or lon.toFloat() > -4.8
          ) {
            valid = false;
            return;
        }
        //
        // Looks good so far so convert to OSI65 Eastings & Northings
        valid = true;
        var numeric_grid_ref = OSI65_latlon_to_numeric_gridref(  WSG84_to_OSI65(lat,lon) );

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
    function toOSGridRef(east, north, precision, valid)
    {
          var t = "";
          var e = "";
          var n = "";
          //
          // Easting & Northing must be >= 0
          if (valid == true && east >= 0 && north >= 0)
          {
            var hundredkmE = floor(east.toDouble() / 100000);
            var hundredkmN = floor(north.toDouble() / 100000);

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
              t = secondLetter;
              valid = true;
            }
            else {
                valid = false;
            }
        }

        if (valid == false) {
            t = "Outside Irl?";
            e = "????";
            n = "????";
        }
        return [t,e,n,valid]; // text, easting, northing, valid
    }


    function WSG84_to_OSI65(lat,lon)
    {
         var phip = lat * deg2rad;
         var lambdap = lon * deg2rad;

//         System.println("WSG84 latitude, longitude: " + lat.toString() + "," + lon.toString() );
         var OSI65_coords = transform_datum(phip, lambdap, WGS84_AXIS, WGS84_ECCENTRIC, MOD_AIRY_AXIS, MOD_AIRY_ECCENTRIC);
//         System.println("OSI65 latitude, longitude: " + OSI65_coords[0].toString() + "," + OSI65_coords[1].toString() );
         return OSI65_coords ;
    }
    // Convert lat / lon to eastings and northings
    //   - Input: 2 element array: [lat,lon]
    //   - Return: 2 element array: [east,north]
    function OSI65_latlon_to_numeric_gridref(OSI65_coords)
    {
        var lat = OSI65_coords[0];
        var lon = OSI65_coords[1];
        // http://www.dorcus.co.uk/carabus//ll_ngr.html
        var phi = lat * deg2rad;      // convert latitude to radians
        var lam = lon * deg2rad;   // convert longitude to radians
        var a = 6377340.189d;       // OSI semi-major axis
        var b = 6356034.447d;        // OSI semi-minor axis
        var e0 = 200000d;           // OSI easting of false origin
        var n0 = 250000d;          // OSI northing of false origin
        var f0 = 1.000035d;     // OSI scale factor on central meridian
        var e2 = 0.00667054015d;  // OSI eccentricity squared
        var lam0 = -0.13962634015954636615389526147909d;  // OSI false east
        var phi0 = 0.93375114981696632365417456114141d;   // OSI false north

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
