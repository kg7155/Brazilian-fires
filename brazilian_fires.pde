import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import java.util.List;

UnfoldingMap map;
HashMap<String, List<StateEntry>> dataEntriesMap;
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
}

HashMap<String, List<StateEntry>> loadFiresDataFromCSV(String fileName) {
  HashMap<String, List<StateEntry>> dataEntriesMap = new HashMap<String, List<StateEntry>>();
  
  String[] rows = loadStrings(fileName);
  
  for (String row : rows) {
    String[] cols = row.split(",");
    if (cols.length >= 4) {    
      StateEntry dataEntry = new StateEntry();
      dataEntry.state = cols[2];
      dataEntry.month = Integer.parseInt(cols[0]);
      dataEntry.year = Integer.parseInt(cols[1]);
      dataEntry.numberOfFires = Integer.parseInt(cols[3]);
      
      if (dataEntriesMap.containsKey(dataEntry.state)) {
        dataEntriesMap.get(dataEntry.state).add(dataEntry);
      } else {
        dataEntriesMap.put(dataEntry.state, new ArrayList<StateEntry>());    
      } 
    }  
  }
  return dataEntriesMap;
}


void draw() {
  background(255);

  map.draw();
}


class StateEntry {
 String state;
 int month;
 int year;
 int numberOfFires;
}
