import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import java.util.List;

UnfoldingMap map;

//HashMap<String, DataEntry> dataEntriesMap;
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
  
}


void draw() {
  background(255);

  // Draw map tiles and country markers
  map.draw();
}

void mousePressed(){
 println(mouseX + " " + mouseY); 
}
