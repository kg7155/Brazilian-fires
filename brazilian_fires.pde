HashMap<String, PShape> shapeStatesMap; // states as PShapes
HashMap<String, ArrayList<StateEntry>> dataEntriesMap; // fire data
PShape psBrazil; // map of Brazil
PGraphics pgView; // view to display (for now only one)
ArrayList<StateEntry> thisStateEntries; // state entries to display
int thisMonth = 8; // month to display
int thisYear = 2016; // year to display

/*----------------------------------------------------------------------*/ 

void setup()
{
  background(255);
  size(1280, 800, P2D);
  
  loadData();
  createViews();
}

/*----------------------------------------------------------------------*/ 

void draw() {
  image(pgView, 0, 0);
  detailState();
}

/*----------------------------------------------------------------------*/ 
// load all data and prepare views

void loadData() {
  // load fire data
  dataEntriesMap = loadFiresDataFromCSV("fires_data.csv");
  
  // load map data and save states separately
  psBrazil = loadShape("brazilLow.svg");
  shapeStatesMap = new HashMap<String, PShape>(); 
  for (String stateCode : dataEntriesMap.keySet()) {
    shapeStatesMap.put(stateCode, psBrazil.getChild(stateCode));  
  }
}

/*----------------------------------------------------------------------*/ 
// create views that enable highlighting on mouse hover

void createViews() {
  pgView = createGraphics(width, height);
  pgView.beginDraw();
  pgView.noStroke();
  pgView.background(255);
  
  for (StateEntry se : thisStateEntries) {
    PShape shapeState = shapeStatesMap.get(se.stateCode);
    shapeState.disableStyle();
    pgView.fill(255, 0, 0, se.transparency);
    pgView.shape(shapeState, 0, 0);
  }
  pgView.endDraw();
}

/*----------------------------------------------------------------------*/
// highlight (by drawing stroke) selected state

void detailState() {
  loadPixels();
  // get transparency value under mouse
  int alphaUnderMouse = 255 - int(green(pgView.pixels[mouseX + mouseY * width]));
  
  for (StateEntry se : thisStateEntries) {
    // compare transparency values
    // if they are the same, the mouse is over current state
    if (se.transparency == alphaUnderMouse) {
      PShape shapeState = shapeStatesMap.get(se.stateCode);
      noFill();
      shape(shapeState, 0, 0);  
    } 
  }
}

/*----------------------------------------------------------------------*/
// create and return data structure containing fire data

HashMap<String, ArrayList<StateEntry>> loadFiresDataFromCSV(String fileName) {
  dataEntriesMap = new HashMap<String, ArrayList<StateEntry>>();
  thisStateEntries = new ArrayList<StateEntry>();
  
  String[] rows = loadStrings(fileName);
  for (String row : rows) {
    String[] cols = row.split(",");
    if (cols.length >= 5) {    
      StateEntry dataEntry = new StateEntry();
      dataEntry.stateCode = cols[0];
      dataEntry.stateName = cols[1];
      dataEntry.month = Integer.parseInt(cols[2]);
      dataEntry.year = Integer.parseInt(cols[3]);
      dataEntry.numOfFires = Math.round(Float.parseFloat(cols[4]));
      dataEntry.transparency = int(map(dataEntry.numOfFires, 0, 25963, 10, 255));
      
      if (dataEntriesMap.containsKey(dataEntry.stateCode)) {
        dataEntriesMap.get(dataEntry.stateCode).add(dataEntry);
      } else {
        dataEntriesMap.put(dataEntry.stateCode, new ArrayList<StateEntry>());    
      }
      
      if (dataEntry.month == thisMonth && dataEntry.year == thisYear) {
        thisStateEntries.add(dataEntry); 
      }
    }  
  }
  return dataEntriesMap;
}

//////////////////////////////////

class StateEntry {
  String stateCode;
  String stateName;
  int month;
  int year;
  int numOfFires;
  int transparency;
}
