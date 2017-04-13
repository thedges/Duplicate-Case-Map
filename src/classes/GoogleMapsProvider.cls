public with sharing class GoogleMapsProvider {

	public static Boolean TESTMODE = true;
    public static GoogleMapsApi CALLOUT;
    
    private static final String BASE_REQUEST_URL = 'https://maps.googleapis.com/maps/api/geocode/json?key=AIzaSyCwI6X2i9prZY_WrJofby1EDk9s8hkj14A&address=';
    private static final String END_QUERY_PARM = '&sensor=false';
    private static final String ENCODING_SCHEME  = 'UTF-8';
        
    public GoogleMapsProvider() 
    {
        if (CALLOUT == null) {
            System.debug('*** NOTE: Callout NOT specified for Google Map API. Using real callout');
            TESTMODE = false;
            GoogleMapsAPi gmApi = new GoogleMapsApi();
            CALLOUT = gmApi;
        }
    }
    
    public Response geocodeAddress(String entireAddress)
    {
        // if all parameters are null or blank, nothing to do so
        if (String.IsBlank(entireAddress))
        {
        	system.debug('All query parameters where null or blank.');
        	return null;
        }
        
        return performGeocoding(entireAddress);    	
    }
    
    public Response geocodeAddress(String addr1, String addr2, String city, String state, String postalCode)
    {
        String queryString = '';
        String comma = '';
        
        if (addr1 != null && addr1 != '')
        {
           queryString = queryString + comma + addr1;
           comma = ',';
        }
           
        if (addr2 != null && addr2 != '')
        {
            queryString = queryString + comma + addr2;
            comma = ',';
        }    
        
        if (city != null && city != '')
        {
            queryString = queryString + comma + city;
            comma = ',';
        }
        
        if (state != null && state != '')
        {
            queryString = queryString + comma + state;
            comma = ',';
        }
        
        if (postalCode != null && postalCode != '')
        {
            queryString = queryString + comma + postalCode;
            comma = ',';
        }
        
        // if all parameters are null or blank, nothing to do so
        if (String.IsBlank(queryString)) {
        	system.debug('All query parameters where null or blank.');
        	return null;
        }
        
        return performGeocoding(queryString);
    }
    
    private Response performGeocoding(String baseQueryString)
    {
        String url = BASE_REQUEST_URL + EncodingUtil.urlEncode(baseQueryString, ENCODING_SCHEME) + END_QUERY_PARM;
            
        try
        {                   
            String response = CALLOUT.callApi(url);
            
            return new Response(response);
        }
        catch(Exception ex)
        {
            System.debug('An unexpected error occured while performing the Geocoding using url: '+url);
            System.debug('Exception: '+ex.getMessage());
            System.debug('StackTrace: '+ex.getStackTraceString());
            
            return null;
        }
    }
    
    private class SpacialReference 
    {
    	Double xCoord;
    	Double yCoord;
    	
    	SpacialReference()
    	{
    		xCoord = 0;
    		yCoord = 0; 
    	}
    }
    
    public class Response
    {
    	public Response(string aJsonString)
    	{
    		system.debug(aJsonString);
	        Response gmResponse = (Response) JSON.deserialize(aJsonString, Response.class);
	        if (gmResponse.status != 'OK')
        		throw new GeocodingException('serializing Google response');

			status = gmResponse.status;
			results = gmResponse.results;
    	}
    	
        public String status;
        public List<ResponseResults> results;      
    }
    
    public class ResponseResults
    {
        List<Address_components> address_components;
        public String formatted_address;
        public Geometry geometry;
        Boolean partial_match;
        List<String> types;
    }
    
    public class Address_components
    {
        String long_name;
        String short_name;
        List<String> types;        
    }
    
    public class Geometry
    {
        Bounds bounds;
        public XedeLatLong.LatitudeLongitude location;
        String location_type;
        Bounds viewport;
    }
    
    public class Bounds
    {
        XedeLatLong.LatitudeLongitude northeast;
        XedeLatLong.LatitudeLongitude southwest;
    }
}