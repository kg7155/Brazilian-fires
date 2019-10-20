/* VISUALISATION: fires vs planting in Brazil
 data from: http://dados.gov.br/dataset/sistema-nacional-de-informacoes-florestais-snif
 */

HashMap<String, PShape> shapeStatesMap; // states as PShapes
HashMap<String, ArrayList<StateEntry>> dataEntriesMap; // my data structure
HashMap<String, Integer> statesColorsMap;
PShape psBrazil; // map of Brazil (http://www.amcharts.com/svg-maps/)
PGraphics idView;
PGraphics myView;
ArrayList<StateEntry> thisStateEntries; // state entries to display
int thisMonth = 8; // month to display
int thisYear = 2014; // year to display

/*----------------------------------------------------------------------*/

void setup()
{
  background(255);
  size(1280, 800, P2D);

  loadData();
  createIdView();
  createView();
}

/*----------------------------------------------------------------------*/

void draw() {
  //background(255);
  image(myView, 0, 0);
  showDetails();
}

/*----------------------------------------------------------------------*/
// load all data

void loadData() {
  // load fire data
  dataEntriesMap = loadFiresDataFromCSV("fires_data.csv");

  // load map data and save states separately
  psBrazil = loadShape("brazilLow.svg");
  shapeStatesMap = new HashMap<String, PShape>(); 
  statesColorsMap = new HashMap<String, Integer>();
  int blue = 255;
  for (String stateCode : dataEntriesMap.keySet()) {
    shapeStatesMap.put(stateCode, psBrazil.getChild(stateCode));
    statesColorsMap.put(stateCode, color(0, 0, blue));
    blue--;
  }
}

/*----------------------------------------------------------------------*/
// create view that enables state identification on mouse hover

void createIdView() {
  idView = createGraphics(width, height);
  idView.beginDraw();
  idView.noStroke();
  idView.background(255);

  for (HashMap.Entry<String, Integer> entry : statesColorsMap.entrySet()) {
    String stateCode = entry.getKey();
    color clr = entry.getValue();

    PShape shapeState = shapeStatesMap.get(stateCode);
    //shapeState.disableStyle();
    shapeState.setFill(clr);
    idView.shape(shapeState);
  }
  idView.endDraw();
}

/*----------------------------------------------------------------------*/
// create visualisation view (currently for only one year)

void createView() {
  myView = createGraphics(width, height);
  myView.beginDraw();
  myView.noStroke();
  myView.background(255);

  for (StateEntry se : thisStateEntries) {
    PShape shapeState = shapeStatesMap.get(se.stateCode);
    shapeState.setFill(color(255, (255 - se.transparency), (255 - se.transparency)));
    myView.shape(shapeState);
  }
  myView.endDraw();
}

/*----------------------------------------------------------------------*/
// highlight selected state by drawing stroke

void showDetails() {
  color mouseClr = idView.get(mouseX, mouseY);
  
  for (StateEntry se : thisStateEntries) {
    PShape shapeState = shapeStatesMap.get(se.stateCode);
    color shapeClr = statesColorsMap.get(se.stateCode);

    // compare colour values: if they are the same, the mouse is over current state
    if (mouseClr == shapeClr) {
      // select and draw current
      shapeState.setStroke(true);
      shapeState.setStroke(color(105, 105, 105));
      shapeState.setStrokeWeight(1);
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
  boolean firstRow = true;
  for (String row : rows) {
    String[] cols = row.split(",");
    if (firstRow) {
      firstRow = false;
      continue;
    }

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
