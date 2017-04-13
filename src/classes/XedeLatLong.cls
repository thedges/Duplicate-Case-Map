public class XedeLatLong {

    public Boolean result {get;set;}
    public String  errorMessage {get;set;}
    public String  detailedErrorMessage {get; set;}
    public String  status {get; set;}
    public Double latitude {get; set;}
    public Double longitude {get; set;}
    public Double spacialX {get; set;}
    public Double spacialY {get; set;}
    
    public XedeLatLong()
    {
        result = false;
        errorMessage = '';
        detailedErrorMessage = '';
        status = '';
        latitude = 0;
        longitude = 0;
        spacialX = 0;
        spacialY = 0;
    }
    
    public static XedeLatLong createFailureLatLong(String errorMessage, String detailedErrorMessage, String status)
    {
        XedeLatLong returnValue = new XedeLatLong();
        returnValue.result = false;
        returnValue.errorMessage = errorMessage;
        returnValue.detailedErrorMessage = detailedErrorMessage;
        returnValue.status = status;
        returnValue.latitude = 0.0;
        returnValue.longitude = 0.0;
        returnValue.spacialX = 0.0;
        returnValue.spacialY = 0.0;
        
        return returnValue;
    }

    public static XedeLatLong createSuccessLatLong(XedeLatLong.LatitudeLongitude internalLatLong, String status)
    {
    	return createSuccessLatLong(internalLatLong, status, 0, 0);
    }
    
    public static XedeLatLong createSuccessLatLong(XedeLatLong.LatitudeLongitude internalLatLong, String status, Double spacialX, Double spacialY)
    {
        XedeLatLong returnValue = new XedeLatLong();
        returnValue.result = true;
        returnValue.errorMessage = '';
        returnValue.status = status;
        returnValue.latitude = internalLatLong.lat;
        returnValue.longitude = internalLatLong.lng;
        returnValue.spacialX = spacialX;
        returnValue.spacialY = spacialY;
        
        return returnValue;
    }   
    
    public static XedeLatLong createSuccessLatLong(Double latitude, Double longitude, String status)
    {        
        return createSuccessLatLong(latitude, longitude, status, 0, 0);
    }
    
    public static XedeLatLong createSuccessLatLong(Double latitude, Double longitude, String status, Double spacialX, Double spacialY)
    {
    	XedeLatLong returnValue = new XedeLatLong();
        returnValue.result = true;
        returnValue.errorMessage = '';
        returnValue.status = status;
        returnValue.latitude = latitude;
        returnValue.longitude = longitude;
        returnValue.spacialX = spacialX;
        returnValue.spacialY = spacialY;
        
        return returnValue;
    }    
    
    public class LatitudeLongitude
    {
        public Double lat;
        public Double lng;
        
        public Double getLatitude()
        {
        	return lat;
        }
        
        public Double getLongitude()
        {
        	return lng;
        }
    }     
}