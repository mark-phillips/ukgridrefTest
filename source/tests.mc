(:test)
function UKUnitTest(logger) {
    logger.debug("UK tests");
    // http://www.movable-type.co.uk/scripts/latlong-gridref.html
    //  651534,313151 | TG 51534 13151 | OSGB36:  52.657277°N 001.719732°E
    check_equal("TG",51534,13152, new OSGridRef(52.657689,1.7178690, 10),logger);
    // SU 47005 29535  | 447005,129535  | OSGB36:  51.062691°N    001.329151°W
    check_equal("SU",47005,29535, new OSGridRef(51.063237,-1.3306010, 10),logger);
    // Howth head trig point
    check_equal("SG", 29421, 93996, new OSGridRef(53.37333339,-6.06932332, 10),logger);

    return (true); // returning true indicates pass, false indicates failure
}

(:test)
function IrishUnitTest(logger) {
    logger.debug("Irish tests");
    // http://irish.gridreferencefinder.com

    // Belfast City hall - http://www.nisra.gov.uk/geography/IG.htm
    check_equal("J",33831,75015, new IrishGridRef(54.60562643,-5.92963357, 10),logger);
    // Spire of Dublin
    // matches: http://www.fieldenmaps.info/cconv/cconv_ie.html where: O 15904 34671 = 53.34979538, -6.2602533 WSG84 = 53.34955887, 6.25928919 IRL65
    //  but not this site:  http://irish.gridreferencefinder.com/
    check_equal("O",15904,34671, new IrishGridRef( 53.34979538, -6.2602533, 10),logger);
    // Newgrange Neolithic tomb, County Meath
    check_equal("O",772,72699, new IrishGridRef(53.694443, -6.475160, 10),logger);
    // Giant's Causeway, County Antrim
    check_equal("C",94702,44836, new IrishGridRef(55.241430,-6.5119421, 10),logger);

    // examples https://www.ordnancesurvey.co.uk/docs/support/irish-grid.pdf
    // OSO (Phoenix Park) OSI Latitude 53 21’ 50”.5441 N Longitude, 06 20’ 52.”9181 W
    check_equal("O",9958,36141, new IrishGridRef(53.36427435,-6.34898583, 10),logger);
    //Howth 53 22’ 23”.1566 N    06 04’ 06”.0065 W
    check_equal("O",28546,37617, new IrishGridRef(53.37333339,-6.06932332, 10),logger);

    return (true);
}

function check_equal(expected_text,expected_easting,expected_northing,gridref,logger)
{
    var gr_string  = gridref.getGR_as_string();
    var message = "Calculated: " +  gr_string
                    + " (Eastings,Northings: " + gridref.easting + "," + gridref.northing + ")."
                    + " - Expected: (" + expected_text + " " + expected_easting+ " " + expected_northing + ")"
                    + " - Given Lat,Long: " + gridref.latitude + "," + gridref.longitude
                    + ")" ;
    var easting_diff = expected_easting - gridref.easting.toNumber();
    var northing_diff = expected_northing - gridref.northing.toNumber();
    if ( easting_diff != 0 or northing_diff != 0 ) {
        logger.warning(message);
    } else {
        logger.debug("OK: " + expected_text + " " + expected_easting+ " " + expected_northing);
    }
    Toybox.Test.assertMessage( gridref.text.equals(expected_text) and (easting_diff.abs()<=1) and (northing_diff.abs()<=1), message);

}