public with sharing class GoogleMapsApi {
    private static final String REQUEST_METHOD   = 'GET';

    public String callApi(String url)
    {
    	try
        {       
            Http httpProtocol = new Http();
                
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod(REQUEST_METHOD);
            
            HttpResponse httpResponse = httpProtocol.send(request);
            
            return httpResponse.getBody();          
        }
        catch(Exception ex)
        {
            System.debug('An unexpected error occured while performing the Geocoding using url: '+url);
            System.debug('Exception: '+ex.getMessage());
            throw new GeocodingException(ex);
        }
    }
}