/* VISUALISATION: fires vs planting in Brazil between 2006 and 2016
 data from: http://dados.gov.br/dataset/sistema-nacional-de-informacoes-florestais-snif
 */

import controlP5.*;
import java.util.*;

HashMap<String, PShape> shapeStatesMap; // states as PShapes
HashMap<String, ArrayList<StateEntry>> dataEntriesMap; // my data structure
HashMap<String, Integer> statesColoursMap; // states colours for id
PShape psBrazil; // map of Brazil (http://www.amcharts.com/svg-maps/)
PGraphics idView; // hidden view that enables state identification
PGraphics[] Views; // other visualisation views

int thisMonth = 1; // month to display
int thisYear = 2006; // year to display
int thisViewIdx; // view index to display
ArrayList<StateEntry> thisStateEntries; // state entries to display

String[] nameOfMonths = new String[] {"January", "February", "March", "April", "May", "June", 
  "July", "August", "September", "October", "November", "December"};
color darkGray = color(127);
PFont font;
ControlP5 cp5Dropdown; // dropdown control

/*----------------------------------------------------------------------*/

void setup()
{
  background(255);
  size(1280, 960, P2D);
  //fullScreen(P2D);

  // load and set font
  font = createFont("SEGOEUI.TTF", 34);
  textFont(font);

  // create GUI elements
  cp5Dropdown = new ControlP5(this);
  createDropdown();

  loadData();
  createIdView();
  createViews();
}

/*----------------------------------------------------------------------*/

void draw() {
  //background(255);
  image(Views[thisViewIdx], 0, 0);
  displayTitle();
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
  statesColoursMap = new HashMap<String, Integer>();
  int blue = 255;
  for (String stateCode : dataEntriesMap.keySet()) {
    PShape child = psBrazil.getChild(stateCode);
    shapeStatesMap.put(stateCode, child);
    statesColoursMap.put(stateCode, color(0, 0, blue));
    blue--;
  }

  // set initial view index
  thisViewIdx = getViewIdx(thisMonth, thisYear);
 
  // set initial state entries to display
  thisStateEntries = getStateEntries(thisMonth, thisYear);
  //println(Arrays.toString(thisStateEntries.toArray()));
  //printDataEntriesMap();
}

/*----------------------------------------------------------------------*/
// create view that enables state identification on mouse hover

void createIdView() {
  idView = createGraphics(width, height);
  idView.beginDraw();
  idView.noStroke();
  idView.background(255);

  for (HashMap.Entry<String, Integer> entry : statesColoursMap.entrySet()) {
    String stateCode = entry.getKey();
    color clr = entry.getValue();

    PShape shapeState = shapeStatesMap.get(stateCode);
    //shapeState.disableStyle();
    shapeState.setFill(clr);
    idView.shape(shapeState, width/3, height/7);
  }
  idView.endDraw();
}

/*----------------------------------------------------------------------*/
// create visualisation views for each month and year

void createViews() {
  // create PGraphics for each view (each month in period 2006-2016)
  Views = new PGraphics[12*11];

  for (int i = 0; i < Views.length; i++) {
    Views[i] = createGraphics(width, height);
  }

  // prepare PGraphics for each view
  int viewIdx = 0;
  for (int year = 2006; year <= 2016; year++) {
    for (int month = 1; month <= 12; month++) {
      Views[viewIdx].beginDraw();
      Views[viewIdx].noStroke();
      Views[viewIdx].background(255);  

      ArrayList<StateEntry> stateEntries = getStateEntries(month, year);

      for (StateEntry se : stateEntries) {
        PShape shapeState = shapeStatesMap.get(se.stateCode);
        color clr = color(255, (255 - se.transparency), (255 - se.transparency));

        shapeState.setFill(clr);
        shapeState.setStroke(true);
        shapeState.setStroke(color(255));
        shapeState.setStrokeWeight(1);
        Views[viewIdx].shape(shapeState, width/3, height/7);
      }
      Views[viewIdx].endDraw();
      viewIdx++;
    }
  }
}

/*----------------------------------------------------------------------*/
// return state entries for corresponding month and year

ArrayList<StateEntry> getStateEntries(int month, int year) {
  ArrayList<StateEntry> stateEntries = new ArrayList<StateEntry>();

  // iterate through states 
  for (ArrayList<StateEntry> dataEntries : dataEntriesMap.values()) {
    // iterate through state entries
    for (StateEntry dataEntry : dataEntries) {
      if ((dataEntry.month == month) && (dataEntry.year == year)) {
        stateEntries.add(dataEntry);
        break;
      }
    }
  }

  return stateEntries;
}

/*----------------------------------------------------------------------*/
// get view index for corresponding month and year

int getViewIdx(int month, int year) {
  return (year-2006) * 12 + month - 1;
}

/*----------------------------------------------------------------------*/
// print my data structure

void printDataEntriesMap() {
  for (Map.Entry<String, ArrayList<StateEntry>> entry : dataEntriesMap.entrySet()) {
    println(entry.getKey());
    for (StateEntry se : entry.getValue()) {
      println(se.stateCode + " " + se.month + " " + se.year);
    }
  }
}

/*----------------------------------------------------------------------*/
// highlight selected state by drawing stroke and data details

void showDetails() {
  color mouseClr = idView.get(mouseX, mouseY);

  for (StateEntry se : thisStateEntries) {
    PShape shapeState = shapeStatesMap.get(se.stateCode);
    color shapeClr = statesColoursMap.get(se.stateCode);

    // compare colour values: if same, the mouse is over current state
    if (mouseClr == shapeClr) {
      // select and draw current
      color stateClr = color(255, (255 - se.transparency), (255 - se.transparency));
      shapeState.setFill(stateClr);
      shapeState.setStroke(true);
      shapeState.setStroke(darkGray);
      shapeState.setStrokeWeight(1);

      shape(shapeState, width/3, height/7);

      fill(darkGray);
      textAlign(CENTER);
      textSize(18);
      text(se.stateName, width/2, height/5*4);
      textSize(14);
      text("Number of fires: " + se.numOfFires, width/2, height/6*5);
    }
  }
}

/*----------------------------------------------------------------------*/
// display title of the visualisation at top centre

void displayTitle() {
  fill(darkGray);
  textSize(20);
  textAlign(CENTER);
  text("Fires vs planted forests in Brazil", width/2, height/18);
  textSize(25);
  text(nameOfMonths[thisMonth-1] + " " + thisYear, width/2, height/11);
}

/*----------------------------------------------------------------------*/
// create and return hashmap containing fire data

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
        dataEntriesMap.get(dataEntry.stateCode).add(dataEntry);
      }
    }
  }
  return dataEntriesMap;
}

/*----------------------------------------------------------------------*/
// create and style dropdown control

void createDropdown() {
  cp5Dropdown.setFont(font, 10);
  cp5Dropdown.setColorCaptionLabel(0);
  
  cp5Dropdown.addScrollableList("dropdown")
    .addItems(Arrays.asList(nameOfMonths))
    .setPosition(width/2, height/7*6)
    .setSize(80, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .setType(ScrollableList.DROPDOWN)
    .setOpen(false)
    .setColorBackground(color(255,0,0,120))
    ;

  cp5Dropdown.get(ScrollableList.class, "dropdown").setValue(thisMonth-1);
}

/*----------------------------------------------------------------------*/
// listen to changes in dropdown selection and react accordingly
// n: selected item index

void dropdown(int n) {
  thisMonth = n+1;
  thisViewIdx = getViewIdx(thisMonth, thisYear);
  thisStateEntries = getStateEntries(thisMonth, thisYear);
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
