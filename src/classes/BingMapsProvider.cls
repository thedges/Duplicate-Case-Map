/**
 * Note: This class requires values Custom Settings or it will throw a ConfigurationException.
 *
 * 1. Save the BingMaps__c object to Salesforce
 * 2. Go to Custom Settings (Develop | Custom Settings)
 * 3. Click on the Manage Action link for BingMaps
 * 4. Click the NEW button at the TOP OF THE PAGE
 * 5. Enter the appropriate field values for
 *       API Endpoint 
 *          Staging value: http://dev.virtualearth.net/REST/v1/Locations
 *          Production value: (tbd)
 *       API Key
 *          Developer value:    
 *          Production value: 
 * 6. Save the record
 *
 *
 * Testing in Execute Annoymous

BingMapsProvider bm = new BingMapsProvider();
BingMapsProvider.Response resp = bm.geocodeAddress('50 West Big Beaver','Suite 100','Troy','Michigan','48084');
System.debug('resp is '+resp);
System.debug('statusCode: '+resp.statusCode);
System.debug('statusDescription: '+resp.statusDescription);
System.debug('lat: '+resp.resourceSets.get(0).resources.get(0).point.coordinates[0]);
System.debug('Long: ' + resp.resourceSets.get(0).resources.get(0).point.coordinates[1]);
 
BingMapsProvider bm = new BingMapsProvider();
BingMapsProvider.Response resp = bm.geocodeAddress('50 West Big Beaver,Troy,Michigan,48084');
System.debug('resp is '+resp);
System.debug('statusCode: '+resp.statusCode);
System.debug('statusDescription: '+resp.statusDescription);
System.debug('lat: '+resp.resourceSets.get(0).resources.get(0).point.coordinates[0]);
System.debug('Long: ' + resp.resourceSets.get(0).resources.get(0).point.coordinates[1]);

BingMapsProvider bm = new BingMapsProvider();
BingMapsProvider.Response resp = bm.geocodeAddress('Benjamin Franklin Bridge, Philadelphia, PA');
System.debug('resp is '+resp);
System.debug('statusCode: '+resp.statusCode);
System.debug('statusDescription: '+resp.statusDescription);
System.debug('lat: '+resp.resourceSets.get(0).resources.get(0).point.coordinates[0]);
System.debug('Long: ' + resp.resourceSets.get(0).resources.get(0).point.coordinates[1]);

BingMapsProvider bm = new BingMapsProvider();
BingMapsProvider.Response resp = bm.geocodeAddress('Franklin Institute, Philadelphia, PA');
System.debug('resp is '+resp);
System.debug('statusCode: '+resp.statusCode);
System.debug('statusDescription: '+resp.statusDescription);
System.debug('lat: '+resp.resourceSets.get(0).resources.get(0).point.coordinates[0]);
System.debug('Long: ' + resp.resourceSets.get(0).resources.get(0).point.coordinates[1]);

BingMapsProvider bm = new BingMapsProvider();
BingMapsProvider.Response resp = bm.geocodeAddress('11th and Arch, Philadelphia, PA');
System.debug('resp is '+resp);
System.debug('statusCode: '+resp.statusCode);
System.debug('statusDescription: '+resp.statusDescription);
System.debug('lat: '+resp.resourceSets.get(0).resources.get(0).point.coordinates[0]);
System.debug('Long: ' + resp.resourceSets.get(0).resources.get(0).point.coordinates[1]);

BingMapsProvider bm = new BingMapsProvider();
BingMapsProvider.Response resp = bm.geocodeAddress('855 N Broad St, Philadelphia, PA ');
System.debug('resp is '+resp);
System.debug('statusCode: '+resp.statusCode);
System.debug('statusDescription: '+resp.statusDescription);
System.debug('lat: '+resp.resourceSets.get(0).resources.get(0).point.coordinates[0]);
System.debug('Long: ' + resp.resourceSets.get(0).resources.get(0).point.coordinates[1]); 
 */
public with sharing class BingMapsProvider
{
	private static Integer SUCCESS_STATUS = 200;
	private static final String ENCODING_SCHEME  = 'UTF-8';
	
    public static BingMapsApi CALLOUT;
    private String apiEndpoint;
    private String apiKey;
    
    public BingMapsProvider()
    {
    	loadProperties();
    	
    	if (CALLOUT == null) 
    	{
            System.debug('*** NOTE: Callout NOT specified for BING Map API. Using real callout');
            BingMapsAPi bmApi = new BingMapsApi();
            CALLOUT = bmApi;
        }
    }
    
    private static final String COUNTRY_REGION_QUERY_PARM = 'CountryRegion=US';
    
    public Response geocodeAddress(String addr1, String addr2, String city, String state, String postalCode)
    {
    	String queryString = COUNTRY_REGION_QUERY_PARM;
    	String ampersand = '&';
    	
        if (addr1 != null && addr1 != '')
        {
           queryString = queryString + ampersand + 'addressLine=' + addr1;
	       if (addr2 != null && addr2 != '')
	       {
	           queryString = queryString + ' ' + addr2;
	       }             
        }
           
        if (city != null && city != '')
        {
            queryString = queryString + ampersand + 'locality=' + city;
        }
        
        if (state != null && state != '')
        {
            queryString = queryString + ampersand + 'adminDistrict=' + state;
        }
        
        if (postalCode != null && postalCode != '')
        {
            queryString = queryString + ampersand + 'postalCode=' + postalCode;
        }
        
        if (queryString == COUNTRY_REGION_QUERY_PARM)
        	throw new GeocodingException('All query parameters where null or blank. (Bad Query, missing parameters)');
        
        return performGeocoding(queryString);
    }
    
    public Response geocodeAddress(String entireAddress)
    {
    	// This needs to use the Location Query API...
    	String baseQuery = String.format('query={0}&includeNeighborhood=1&include=queryParse', 
    							new String[] 
    							{ 
    								EncodingUtil.urlEncode(entireAddress, ENCODING_SCHEME) 	// 0 - Do I need to encode this??
    							}
    						);

		return performGeocoding(baseQuery);
    }
    
	// status codes 
	// 200 = success 
	// 400 = Bad Request - The request contained an error
    // 401 = Unauthorized - Access was denied. Missing/invalid credentials
    // 500 = Internal Server Error - Request not completed because there was a problem with the service
    // 503 = Service Unavailable - There's a problem with the service right now. Please try again later.    
        
    private Response performGeocoding(String baseQueryString)
    {
    	String url = apiEndpoint + '?' + baseQueryString + '&key=' + apiKey;
    	System.debug('The BingMapURL is '+url);
    	try
    	{
    		String serviceResponse = CALLOUT.callApi(url);
          
            return parseResponse(serviceResponse);
    	}
        catch(Exception ex)
        {
            System.debug('An unexpected error occured while performing the Geocoding (bing) using url: '+url);
            System.debug('Exception: '+ex.getMessage());
            System.debug('StackTrace: '+ex.getStackTraceString());
            
            return null;
        }
    }
       
 
        
    private void loadProperties() 
    {
    	// TODO: refactor into custom setting, etc
    	this.apiEndpoint = 'https://dev.virtualearth.net/REST/v1/Locations';
    	this.apiKey = 'AtQ8JIbYNtG6oVxXaL-Me7EWZ3PABYydGdIf-vC7CN6a0DCvYx5l5hndGdKYyZAI';
    	/*
        BingMaps__c maps = BingMaps__c.getOrgDefaults();
        if (maps == null || maps.API_Endpoint__c == null || maps.API_Key__c == null ) 
        {
            throw new ConfigurationException('FATAL: Missing org defaults for BingMaps');
        }
        
        System.debug('Using the following BingMaps properites');
        System.debug('API Endpoint: '+maps.API_Endpoint__c);
        System.debug('API Key: '+maps.API_Key__c);
        
        this.apiEndpoint = maps.API_Endpoint__c;
        this.apiKey = maps.API_Key__c;
        */
    }
    
	public class BingMapResponse
	{
        Integer statusCode;
        List<String> errorDetails;
        String statusDescription;
        String traceId;	    
        List<Double> coordinates;
	}
	
	public static Response ParseResponse(String aJsonString)
	{
		System.debug(aJsonString);
		
		// first we need to search/replace for reserved words...
		// "__type" --> "bboxType"
		// "type" -> "pointType"
		// 
		
		String fixedUpJson = aJsonString.replaceAll('"__type"','"bboxType"');
		fixedUpJson = fixedUpJson.replaceAll('"type"','"pointType"');
		
		Response bmResponse = (Response) JSON.deserialize(fixedUpJson, Response.class);
		if (bmResponse.statusCode != SUCCESS_STATUS)
			throw new GeocodingException('Deserializing Bing Reponse');
			
		return bmResponse;
	}
	
	public class Response
	{		
		public String authenticationResultCode;
		public String brandLogoUri;
		public String copyright;
		public List<ResourceSet> resourceSets;
		
        public Integer statusCode;
        public String statusDescription;
        
        public String traceId;	 
        List<String> errorDetails;
	}
	
	public class ResourceSet
	{
		public Integer estimatedTotal;
		public List<Resource> resources;		
	}
	
	public class Resource
	{
		public String bboxType;
		public List<Double> bbox;
		public String name;
		public BingPoint point; 
		public BingAddress address;
		public String confidence;
		public String entityType;
		public List<BingGeocodePoint> geocodePoints;
		public List<String> matchCodes;
	}
		
	public class BingPoint
	{
		public String pointType;
		public List<Double> coordinates;
	}
	
	/*
	public class BingBoundingBox
	{
		public Double southLatitude;
		public Double westlogitude;
		public Double northLatitude;
		public Double eastLongitude;
	}
	*/
	
	public class BingAddress
	{
		public String addressLine1;
		public String adminDistrict;
		public String adminDistrict2;
		public String countryRegion;
		public String formattedAddress;
		public String locality;
		public String postalCode;
	}
	
	public class BingGeocodePoint
	{
		public String pointType;
		public List<Double> coordinates;
		public String calculationMethod;
		public List<String> usageTypes;
	}


}