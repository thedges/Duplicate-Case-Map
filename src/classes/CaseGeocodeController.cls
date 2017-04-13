global class CaseGeocodeController extends XedeController {

    @RemoteAction global static string RelateCaseAndClose(string parentCaseId, string childCaseId) {
        list<string> idList = new list<string>(new string[] { parentCaseId, childCaseId });

        map<id, Case> caseMap = new map<id, Case>([select id, caseNumber, parentId, status, reason from Case where id in :idList ]);
        if (caseMap.size() != 2) {
            return 'Both old and new cases were not found.';
        }

        Case child = caseMap.get(childCaseId);
        Case parent = caseMap.get(parentCaseId);

        child.status = 'duplicate';
        child.reason = 'Duplicate';
        child.parentId = parentCaseId;
        try {
            update child;
        } catch (system.dmlexception ex) {
            return ex.getMessage();
        }

        return 'Made ' + parent.caseNumber + ' parent and marked ' + child.caseNumber + ' as a duplicate.';
    }

    @RemoteAction global static ESRILocator.FindAddressResponse AddressLocator(string spatialReference, string anAddress) {

        ESRILocator locator = new ESRILocator();
        ESRILocator.FindAddressResponse response = locator.findAddressCandidates(spatialReference.replaceAll('[^-.\\d]', ''), anAddress);

        return response;
    }

    @RemoteAction global static ESRILocator.Address AddressGeocode(string anId, string spatialReference) {
        try {
            Case c = [ select id, address__c, location__latitude__s, location__longitude__s, street__c, address_x__c, address_y__c from case where id = :anId ];

            /*
            if (String.IsBlank(c.Street__c) == false && c.Address_X__c != null && c.Address_X__c != 0.0)
                return ESRILocator.AddressFor(c.street__c, c.address_x__c, c.address_y__c);
            */

            if (String.IsBlank(c.address__c)) {
                return null;
            }

            if (c.location__latitude__s != null && c.location__longitude__s != null) {
                ESRILocator.Address add = new ESRILocator.Address(c.address__c, Decimal.valueOf('' + c.location__longitude__s),
                        Decimal.valueOf('' + c.location__latitude__s));
                return add;
            }

            ESRILocator.FindAddressResponse response = AddressLocator(spatialReference, c.address__c);
            if (response.isEmpty()) {
                return null;
            }

            ESRILocator.Address address = response.candidates[0];

            return address;
        } catch (system.Dmlexception e) {
            system.debug(e.getMessage());
        }

        return null;
    }

    public CaseGeocodeController(ApexPages.StandardController controller) {
        esriConfig = ESRI_Config__c.GetInstance('Default');

        this.controller = controller;
        this.aCase = (Case) controller.getRecord();
    }

    // fired when the search button is clicked
    public PageReference geocode() {
        ESRILocator aLocator = new ESRILocator();
        ESRILocator.FindAddressResponse response = aLocator.findAddressCandidates(
                    aCase.Street__c
                );

        if (response.candidates.isEmpty()) {
            return null;
        }

        ESRILocator.Address anAddress = response.candidates[0];
        aCase.Address_Geocode__Latitude__s = anAddress.location.x;
        aCase.Address_Geocode__Longitude__s = anAddress.location.y;

        aCase.Address_X__c = anAddress.location.x;
        aCase.Address_Y__c = anAddress.location.y;

        return null;
    }

    @RemoteAction global static list<Case> GetRecentCases(integer rowLimit, string anId) {
        list<Case> aList = new list<Case>();

        try {
            aList = [
                        select  id,
                        caseNumber,
                        type,
                        street__c,
                        subject,
                        status,
                        createdDate,
                        createdBy.name,
                        description,
                        address_x__c,
                        address_y__c,
                        createdDateString__c,
                        closedDateString__c
                        from  Case
                        where  id != :anId
                        and  address_x__c != null
                        and  address_y__c != null
                        order by CreatedDate DESC
                        limit :rowLimit
                    ];
        } catch (system.Dmlexception e) {
            system.debug(e.getMessage());
        }

        return aList;
    }

    @RemoteAction global static list<Case> GetRelatedCases(integer rowLimit, string anId, string aType) {
        Decimal lat = null;
        Decimal lng = null;
        List<Case> aList = new List<Case>();

        // select Id, CaseNumber, CreatedDate from Case where CreatedDate > 2017-03-17T00:00:00Z

        if (anId != null) {
            //////////////////////////////////////
            // get lat/lng of the case in focus //
            //////////////////////////////////////
            Case c = [SELECT Id, CaseNumber, Location__Latitude__s, Location__Longitude__s FROM Case WHERE Id = :anId];
            lat = c.Location__Latitude__s;
            lng = c.Location__Longitude__s;
            System.debug('lat=' + lat + ' lng=' + lng);

            Date compareDate = Date.Today().addDays(-5);
        

            //////////////////////////////////////////////
            // get related cases within 0.5 mile radius //
            //////////////////////////////////////////////
            if (lat != null && lng != null) {
                try {
                    aList = [
                                select  id,
                                caseNumber,
                                type,
                                address__c,
                                subject,
                                status,
                                createdDate,
                                createdBy.name,
                                description,
                                location__latitude__s,
                                location__longitude__s,
                                address_x__c,
                                address_y__c,
                                createdDateString__c,
                                closedDateString__c
                                from  Case
                                where  id != :anId
                                and  Type = :aType
                                            and  location__latitude__s != null
                                            and  location__longitude__s != null
                                            and DISTANCE(Location__c, GEOLOCATION(:lat,:lng), 'mi') < 0.5
                                //            and CreatedDate > :compareDate
                                ORDER BY DISTANCE(Location__c, GEOLOCATION(:lat,:lng), 'mi')
                                LIMIT :rowLimit
                            ];
                } catch (system.Dmlexception e) {
                    system.debug(e.getMessage());
                }
            } else {


                try {
                    aList = [
                                select  id,
                                caseNumber,
                                type,
                                address__c,
                                subject,
                                status,
                                createdDate,
                                createdBy.name,
                                description,
                                location__latitude__s,
                                location__longitude__s,
                                address_x__c,
                                address_y__c,
                                createdDateString__c,
                                closedDateString__c
                                from  Case
                                where  id != :anId
                                and  Type = :aType
                                            and  location__latitude__s != null
                                            and  location__longitude__s != null
                                            order by CreatedDate DESC
                                            limit :rowLimit
                            ];
                } catch (system.Dmlexception e) {
                    system.debug(e.getMessage());
                }
            }

        }
        return aList;
    }

    public pageReference createCase() {
        pageReference pageref = controller.save();
        pageReference editPageReference = new PageReference(pageref.getUrl());
        editPageReference.setRedirect(true);
        return editPageReference;
    }

    ApexPages.StandardController controller {get; set;}
    public Case aCase { get; private set; }
    public ESRI_Config__c esriConfig { get; private set; }
}