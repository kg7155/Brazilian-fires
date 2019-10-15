import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import java.util.List;

UnfoldingMap map;
HashMap<String, ArrayList<StateEntry>> dataEntriesMap;
List<Marker> stateMarkers;

void setup() {
  size(800, 800, P2D);
  smooth();

  map = new UnfoldingMap(this, 50, 50, 700, 700);
  map.zoomAndPanTo(286, 417, 4);
  map.setBackgroundColor(255);
  MapUtils.createDefaultEventDispatcher(this, map);

  // Load state polygons and add them as markers
  List<Feature> states = GeoJSONReader.loadData(this, "brazil-states.geo.json");
  stateMarkers = MapUtils.createSimpleMarkers(states);
  map.addMarkers(stateMarkers);
  
  // Load fires data
  dataEntriesMap = loadFiresDataFromCSV("fires_data.csv");
  println("Loaded " + dataEntriesMap.size() + " data entries");
  
  // Shade states according to fire density
  shadeStates();
}

void draw() {
  background(255);

  map.draw();
}

void shadeStates() {
  for (Marker marker : stateMarkers) {
    // Find data for state of the current marker
    String stateName = marker.getProperty("name").toString(); 
    if (dataEntriesMap.containsKey(stateName)) {
      ArrayList<StateEntry> stateEntries = dataEntriesMap.get(stateName);
      
      if (stateEntries != null) {
        int numOfFires = getNumOfFires(stateEntries, 2017, 8);
        float transparency = map(numOfFires, 0, 25963, 10, 255);
        marker.setColor(color(255, 0, 0, transparency));  
      }
    }
  }
}

int getNumOfFires(ArrayList<StateEntry> stateEntries, int year, int month){
    for (StateEntry state : stateEntries){
      if (state.getMonth() == month && state.getYear() == year) {
        return state.numOfFires;  
      }
    }
    return 0;
}

HashMap<String, ArrayList<StateEntry>> loadFiresDataFromCSV(String fileName) {
  HashMap<String, ArrayList<StateEntry>> dataEntriesMap = new HashMap<String, ArrayList<StateEntry>>();
  
  String[] rows = loadStrings(fileName);
  
  for (String row : rows) {
    String[] cols = row.split(",");
    if (cols.length >= 4) {    
      StateEntry dataEntry = new StateEntry();
      dataEntry.state = cols[2];
      dataEntry.month = Integer.parseInt(cols[0]);
      dataEntry.year = Integer.parseInt(cols[1]);
      dataEntry.numOfFires = Math.round(Float.parseFloat(cols[3]));
      
      if (dataEntriesMap.containsKey(dataEntry.state)) {
        dataEntriesMap.get(dataEntry.state).add(dataEntry);
      } else {
        dataEntriesMap.put(dataEntry.state, new ArrayList<StateEntry>());    
      } 
    }  
  }
  return dataEntriesMap;
}


class StateEntry {
 String state;
 int month;
 int year;
 int numOfFires;
 
 public int getMonth(){
   return this.month;  
 }
 
 public int getYear(){
   return this.year;  
 }
}
