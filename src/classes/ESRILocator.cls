global class ESRILocator {
    global class Location {
        public double x;
        public double y;    
        
        Location(decimal anX, decimal aY) { x = anX; y = aY; }  
    }
    
    global class Address {
        public string address;
        public string city;
        public string state;
        public string zip;
        public string streetName;
        public string preDir;
        public Location location;
        public double score;
        
        public Address(string street, decimal x, decimal y)
        {
            location = new Location(x, y);
            address = street;
            score = 0.0;
        }
    }
    
    global class Geometry {
        public double x;
        public double y;
    }
    
    global class ProjectResponse {
        public string geometryType;
        list<Geometry> geometries;
    }
    
    global class FindAddressResponse {
        public FindAddressResponse()
        {
            spatialReference = new map<string, string>();
            candidates = new list<Address>();
        }
        
        public FindAddressResponse(GoogleMapsProvider.Response response)
        {
            this();
            spatialReference.put('wkid', '4326');
            
            system.debug('GMResponse # candidates = ' + response.results.size());
            
            for (GoogleMapsProvider.ResponseResults each : response.results)
            {
                candidates.add(new Address(each.formatted_Address, each.geometry.location.lng, each.geometry.location.lat));
            }
            
            system.debug('ESRIResponse # candidates = ' + candidates.size());
        }   
        
        public FindAddressResponse(BingMapsProvider.Response response)
        {
            this();
            
            system.assertEquals(1, response.resourceSets.size());
            
            spatialReference.put('wkid', '4326');
            
            system.debug('BingResponse # candidates = ' + response.resourceSets[0].resources.size());
            
            for (BingMapsProvider.resource each : response.resourceSets[0].resources)
            {
                candidates.add(new Address(each.address.formattedAddress, each.geocodePoints[0].coordinates[1], each.geocodePoints[0].coordinates[0]));
            }
            
            system.debug('ESRIResponse # candidates = ' + candidates.size());
        }
        
        
            
        public boolean isEmpty() { return candidates == null ? true : candidates.isEmpty(); }
        
        public FindAddressResponse projectToSpatialReference(string aReference)
        {       
            list<string> aList = new list<string>();
            for (Address each : candidates) {
                aList.add(String.ValueOf(each.location.x));
                aList.add(String.ValueOf(each.location.y));
            }
            
            string xyListString = String.Join(aList, ',');
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            String returnFields = EncodingUtil.UrlEncode('city,state,zip,predir,streetName', 'utf-8');      
            
            request.setMethod('GET');
            request.setTimeout(60000);      
            
            string formatString = 'https://tasks.arcgisonline.com/ArcGIS/rest/services/Geometry/GeometryServer/project?inSR={0}&outSR={1}&geometries={2}&f=json';
            
            request.setEndpoint(
                String.Format(
                    formatString,
                    new String[] {
                        spatialReference.get('wkid'),                   // 0
                        aReference,                                     // 1
                        EncodingUtil.UrlEncode(xyListString, 'utf-8')   // 2
                    }
                )
            );
            
            Httpresponse response = http.send(request);
            
            string jsonString = response.getBody();
            system.debug(jsonString);  
            
            ProjectResponse aProjectResponse = (ProjectResponse) JSON.Deserialize(jsonString, ProjectResponse.class);
            
            for (integer i = 0; i < aProjectResponse.geometries.size(); i++)
            {
                Geometry newGeometry = aProjectResponse.geometries[i];
                candidates[i].location.x = newGeometry.x;
                candidates[i].location.y = newGeometry.y;
            }
            
            spatialReference.put('wkid', aReference);
            
            return this;
        }
        
        public integer size() { return candidates == null ? 0 : candidates.size(); }
        
        public map<string, string> spatialReference;
        public list<Address> candidates;
    }
    
    public static Address AddressFor(string street, decimal x, decimal y)
    {
        Address response = new Address(street, x, y);
        system.debug('response = ' + response);
        return response;
    }
    
    public ESRILocator()
    {
        this('Default');
    }
    
    public ESRILocator(ApexPages.StandardController controller) {
        this();
    }
    
    public ESRILocator(string baseURI)
    {
        if (baseURI.indexOf('/') >= 0) {
            config = new ESRI_Config__c();
            config.Locator__c = baseURI;
            config.City__c = null;
            config.State__c = null;
        }
        else {
            config = ESRI_Config__c.GetInstance(baseURI);
            system.assertNotEquals(null, config, 'Unable to find locator for config named "' + baseURI + '"');
        }
    }
    
    @RemoteAction global static ESRILocator.FindAddressResponse FindAddress(string anAddress)
    {
        ESRILocator aLocator = new ESRILocator();
        return aLocator.findAddressCandidates(anAddress);
    }   
    
    public FindAddressResponse findAddressCandidates(string address)
    {
        return findAddressCandidates('', address);
    }
    
    public FindAddressResponse findAddressCandidates(string spatialReference, string address)
    {
        return findAddressCandidatesFromGoogle(spatialReference, address);
        //return findAddressCandidatesFromBing(spatialReference, address);
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        string returnFields = EncodingUtil.UrlEncode('city,state,zip,predir,streetName', 'utf-8');      
        
        request.setMethod('GET');
        request.setTimeout(60000);
            
        string encodedAddress = EncodingUtil.UrlEncode(address, 'utf-8');
        
        string formatString = '{0}/findAddressCandidates?f=json&outSR={1}&Single+Line+Input={2}&outfields={3}';
        if (config.Locator__c.tolowercase().contains('_na_10'))
            formatString = '{0}/findAddressCandidates?f=json&outSR={1}&SingleLine={2}&outfields={3}';
        
        request.setEndpoint(
            String.Format(
                formatString,
                new string[] { 
                    config.Locator__c,  // 0
                    spatialReference,   // 1
                    encodedAddress,     // 2
                    returnFields        // 3
                } 
            )
        );
        
        Httpresponse response = http.send(request);
        
        string jsonString = response.getBody();
        system.debug(jsonString);
        
        FindAddressResponse aResponse = (FindAddressResponse) Json.Deserialize(jsonString, FindAddressResponse.class);
        return aResponse;
    }
    
    public FindAddressResponse findAddressCandidates(string street, string city, string state, string postal, string country)
    {
        
        return findAddressCandidates(String.Format(
            '{0}, {1}, {2} {3} {4}', 
            new string[] {
                street, 
                city,
                state,
                postal,
                country
            }
        ));
    }
    
    public FindAddressResponse findAddressCandidatesFromBing(string reference, string address)
    {
        BingMapsProvider aProvider = new BingMapsProvider();
        BingMapsProvider.Response aGMResponse = aProvider.geocodeAddress(address);
        
        EsriLocator.FindAddressResponse esriResponse = new EsriLocator.FindAddressResponse(aGMResponse);
        system.debug(esriResponse);
        esriResponse.projectToSpatialReference(reference);
        system.debug(esriResponse);
        return esriResponse;
    }
    
    public FindAddressResponse findAddressCandidatesFromGoogle(string reference, string address)
    {
        GoogleMapsProvider aProvider = new GoogleMapsProvider();
        GoogleMapsProvider.Response aGMResponse = aProvider.geocodeAddress(address);
        
        EsriLocator.FindAddressResponse esriResponse = new EsriLocator.FindAddressResponse(aGMResponse);
        system.debug(esriResponse);
        esriResponse.projectToSpatialReference(reference);
        system.debug(esriResponse);
        return esriResponse;
    }
    
    public string services()
    {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setMethod('POST');
        request.setEndpoint(config.Locator__c + '/arcgis/rest/services?f=json');
        Httpresponse response = http.send(request);
        return response.getBody();      
    }

    ESRI_Config__c config;
}