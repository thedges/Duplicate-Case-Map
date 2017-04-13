# Duplicate-Case-Map

Sample code that includes a Visualforce page (ArcGisTest) to use in Salesforce console that shows similar/like cases. The map has pop-up that allows you to select another case as parent which then marks current case as duplicate. Typically used in scenarios like 311 to have call center agents find duplicate cases (i.e. pink elephant on street).

Review the CaseGeocodeController::GetRelatedCases() method and adjust the logic for retrieving similar cases.

Screenshot of map component in console
![alt text](https://github.com/thedges/Duplicate-Case-Map/blob/master/ScreenShot-Duplicate-Case.png "Sample Screenshot")

Configuration of component in layout editor
![alt text](https://github.com/thedges/Duplicate-Case-Map/blob/master/Screenshot-Console-Layout.png "Layout Editor Screenshot")

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>
