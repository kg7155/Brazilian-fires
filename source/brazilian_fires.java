import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class brazilian_fires extends PApplet {



HashMap<String, PShape> shapeStatesMap; // states as PShapes
HashMap<String, ArrayList<StateEntry>> dataEntriesMap; // my data structure
HashMap<String, Integer> statesColoursMap; // states colours for id
HashMap<String, int[]> coordinatesMap; // states coordinates
PShape psBrazil; // map of Brazil (http://www.amcharts.com/svg-maps/)
PGraphics idView; // a hidden view that enables state identification
PGraphics[] Views; // other visualisation views

int startMonth = 1; // start month from data
int startYear = 2006; // start year from data
int endYear = 2016; // end year from data
int midYear = startYear + (endYear-startYear) / 2; // calculated mid year
int numYears = endYear - startYear + 1; // number of years

int thisMonth = 1; // month to display
int thisYear = 2006; // year to display
int thisViewIdx; // view index to display
ArrayList<StateEntry> thisStateEntries; // state entries to display

String[] nameOfMonths = new String[] {"January", "February", "March", "April", "May", "June", 
  "July", "August", "September", "October", "November", "December"};

int svgMapHeight = 633;
int graphicsHeight;
int graphicsWidth;
int graphicsX;
int graphicsY;
float scaleFactor;

int darkGray = color(127);
int green = color(182, 239, 148);
int lightPink = color(255, 205, 205);
int lowestAlphaRed = color(255, 245, 245);
int highestAlphaRed = color(255, 0, 0);

PFont font;
Timeline tlMonths;
Timeline tlYears;
Button btn;

/*----------------------------------------------------------------------*/

public void setup() {
  background(255);
  
  

  // set graphics position constants
  graphicsWidth = width/3;
  graphicsHeight = height*3/5;
  graphicsX = width/3;
  graphicsY = height/7-15;
  scaleFactor = (float)graphicsHeight/(float)svgMapHeight;

  // load and set font
  font = createFont("SEGOEUI.TTF", 34);
  textFont(font);

  // create GUI elements
  btn = new Button(width/2, height-140);
  tlMonths = new Timeline(width/2+28, height-102, 'm');
  tlYears = new Timeline(width/2, height-50, 'y');

  loadData();

  // create views
  createIdView();
  createViews();
}

/*----------------------------------------------------------------------*/

public void draw() {
  background(255);

  btn.rollover(mouseX, mouseY);
  btn.applyButton();
  tlMonths.rollover(mouseX, mouseY);
  tlYears.rollover(mouseX, mouseY);

  image(Views[thisViewIdx], graphicsX, graphicsY);

  displayTitle();
  displayLegends(width-200, height/21);
  btn.display();
  tlMonths.display();
  tlYears.display();

  showDetails();
}

public void mousePressed() {
  btn.press(mouseX, mouseY);
  tlMonths.press(mouseX, mouseY);
  tlYears.press(mouseX, mouseY);
}

public void mouseReleased() {
  btn.noPress();
  tlMonths.noPress();
  tlYears.noPress();
}

/*----------------------------------------------------------------------*/
// load all data

public void loadData() {
  dataEntriesMap = loadFiresDataFromCSV("fires_data.csv");
  loadPlantData("planted_forests_data.csv");
  coordinatesMap = loadCoordinatesFromCSV("positions.csv");

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
}

/*----------------------------------------------------------------------*/
// create view that enables state identification on mouse hover

public void createIdView() {
  idView = createGraphics(graphicsWidth, graphicsHeight);
  idView.beginDraw();
  idView.noStroke();
  idView.background(255);
  idView.push();
  idView.scale(scaleFactor);
  for (HashMap.Entry<String, Integer> entry : statesColoursMap.entrySet()) {
    String stateCode = entry.getKey();
    int clr = entry.getValue();

    PShape shapeState = shapeStatesMap.get(stateCode);
    shapeState.setFill(clr);

    idView.shape(shapeState);
  }
  idView.pop();
  idView.endDraw();
}

/*----------------------------------------------------------------------*/
// create visualisation views for each month and year

public void createViews() {
  // create PGraphics for each view (each month in period 2006-2016)
  Views = new PGraphics[12*11];

  for (int i = 0; i < Views.length; i++) {
    Views[i] = createGraphics(graphicsWidth, graphicsHeight);
  }

  // prepare PGraphics for each view
  int viewIdx = 0;
  for (int year = startYear; year <= endYear; year++) {
    for (int month = 1; month <= 12; month++) {
      Views[viewIdx].beginDraw();
      Views[viewIdx].push();
      Views[viewIdx].scale(scaleFactor);
      Views[viewIdx].noStroke();
      Views[viewIdx].background(255);  

      ArrayList<StateEntry> stateEntries = getStateEntries(month, year);

      // draw state shapes
      for (StateEntry se : stateEntries) {
        PShape shapeState = shapeStatesMap.get(se.stateCode);
        int clr = color(255, (255 - se.transparency), (255 - se.transparency));

        shapeState.setFill(clr);
        shapeState.setStroke(true);
        shapeState.setStroke(color(255));
        shapeState.setStrokeWeight(1);

        Views[viewIdx].shape(shapeState);
      }

      Views[viewIdx].noStroke();
      // draw circles for planted forests
      for (StateEntry se : stateEntries) {
        if (se.plantedArea != 0) {
          int[] xy = coordinatesMap.get(se.stateCode);
          int size = PApplet.parseInt(map(se.plantedArea, 13901, 1536310, 10, 70));
          Views[viewIdx].fill(green);
          float xx = (xy[0]-graphicsX/scaleFactor);
          float yy = (xy[1]-graphicsY/scaleFactor);
          Views[viewIdx].ellipse(xx, yy, size, size);
          if (year == startYear && month == startMonth)
            println("drawing " + se.stateCode + " ellipse at: " + xx + " " + yy);
        }
      }
      Views[viewIdx].pop();
      Views[viewIdx].endDraw();
      viewIdx++;
    }
  }
}

/*----------------------------------------------------------------------*/
// return state entries for corresponding month and year

public ArrayList<StateEntry> getStateEntries(int month, int year) {
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
// return state entries for corresponding state and year

public ArrayList<StateEntry> getStateEntries(String stateCode, int year) {
  ArrayList<StateEntry> stateEntries = new ArrayList<StateEntry>();

  // iterate through states 
  for (ArrayList<StateEntry> dataEntries : dataEntriesMap.values()) {
    // iterate through state entries
    for (StateEntry dataEntry : dataEntries) {
      if ((dataEntry.stateCode.equals(stateCode)) && (dataEntry.year == year)) {
        stateEntries.add(dataEntry);
      }
    }
  }
  return stateEntries;
}

/*----------------------------------------------------------------------*/
// get view index for corresponding month and year

public int getViewIdx(int month, int year) {
  return (year-startYear) * 12 + month - 1;
}

/*----------------------------------------------------------------------*/
// get month and year from view index

public int[] getMonthYear(int viewIdx) {
  int yearIdx = viewIdx/12; // year idx

  int[] my = new int[2];
  my[0] = viewIdx - yearIdx*12 + 1; // month
  my[1] = yearIdx + startYear; // year

  return my;
}

/*----------------------------------------------------------------------*/
// print my data structure

public void printDataEntriesMap() {
  for (Map.Entry<String, ArrayList<StateEntry>> entry : dataEntriesMap.entrySet()) {
    println(entry.getKey());
    for (StateEntry se : entry.getValue()) {
      println(se.stateCode + " " + se.month + " " + se.year + " " + se.plantedArea);
    }
  }
}

/*----------------------------------------------------------------------*/
// highlight selected state by drawing stroke and data details

public void showDetails() {
  int mouseClr = idView.get(mouseX-graphicsX, mouseY-graphicsY);

  push();
  scale(scaleFactor);

  for (StateEntry se : thisStateEntries) {
    PShape shapeState = shapeStatesMap.get(se.stateCode);
    int shapeClr = statesColoursMap.get(se.stateCode);

    // compare colour values: if same, the mouse is over current state
    if (mouseClr == shapeClr) {
      // select and draw current
      int stateClr = color(255, (255 - se.transparency), (255 - se.transparency));
      shapeState.setFill(stateClr);
      shapeState.setStroke(true);
      shapeState.setStroke(darkGray);
      shapeState.setStrokeWeight(1);

      shape(shapeState, graphicsX / scaleFactor, graphicsY / scaleFactor);

      noStroke();
      if (se.plantedArea != 0) {
        int[] xy = coordinatesMap.get(se.stateCode);
        int size = PApplet.parseInt(map(se.plantedArea, 13901, 1536310, 10, 70));
        fill(green);
        ellipse(xy[0], xy[1], size, size);
      }

      fill(darkGray);
      textAlign(CENTER);
      textSize(18);
      text(se.stateName, width/2/scaleFactor, height*5/7/scaleFactor+50);
      textSize(14);
      text("Number of fires: " + se.numOfFires, width/2/scaleFactor, height*5/7/scaleFactor+70);

      if (se.plantedArea != 0)
        text("Planted forests area: " + se.plantedArea + " ha", width/2/scaleFactor, height*5/7/scaleFactor+90);
    }
  }

  pop();
}

/*----------------------------------------------------------------------*/
// display title of the visualisation at top centre

public void displayTitle() {
  fill(darkGray);
  textSize(25);
  textAlign(CENTER);
  text("Fires vs planted forests in Brazil", width/2, height/18);
  textSize(20);
  text(nameOfMonths[thisMonth-1] + " " + thisYear, width/2, height/11);
}

/*----------------------------------------------------------------------*/
// display legends for number of fires and planted forests area 

public void displayLegends(int x, int y) {
  // number of fires legend
  textSize(14);
  textAlign(LEFT);
  fill(darkGray);
  text("Number of fires:", x, y);

  int h = 150;
  int w = 20;
  noFill();
  // draw top to bottom gradient
  for (int i = y+20; i <= y+20+h; i++) {
    float inter = map(i, y, y+20+h, 0, 1);
    int c = lerpColor(lowestAlphaRed, highestAlphaRed, inter);
    stroke(c);
    line(x, i, x+w, i);
  }

  // draw numbers
  fill(darkGray);
  int step = 6500;
  for (int i = 0, j = 1; i <= 26000; i = i+step, j++) {
    text(i, x+30, y-10+h*j/4);
  }

  // planted forests area legend
  noStroke();
  text("Planted forests area [ha]:", x, y+h+100);

  int[] sizes = new int[] {15000, 150000, 1500000};
  int[] ys = new int[] {y+270, y+300, y+350};

  // draw circles
  for (int i = 0; i < sizes.length; i++) {
    int size = sizes[i];
    int cs = PApplet.parseInt(map(size, 13901, 1536310, 10, 60));
    fill(green);
    ellipse(x+8, ys[i], cs, cs);

    // draw numbers
    fill(darkGray);
    text(sizes[i], x+45, ys[i]+5);
  }
}

/*----------------------------------------------------------------------*/
// create and return hashmap containing fire data

public HashMap<String, ArrayList<StateEntry>> loadFiresDataFromCSV(String fileName) {
  dataEntriesMap = new HashMap<String, ArrayList<StateEntry>>();
  thisStateEntries = new ArrayList<StateEntry>();

  String[] rows = loadStrings(fileName);
  // skip header
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
      dataEntry.transparency = PApplet.parseInt(map(dataEntry.numOfFires, 0, 25963, 10, 255));

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
// load planted forests area data

public void loadPlantData(String fileName) {
  String[] rows = loadStrings(fileName);
  // skip header
  boolean firstRow = true;
  for (String row : rows) {
    String[] cols = row.split(",");
    if (firstRow) {
      firstRow = false;
      continue;
    }

    if (cols.length >= 4) {
      String stateCode = cols[0];
      int year = Integer.parseInt(cols[2]);
      int plantedArea = Integer.parseInt(cols[3]);

      // add planted area to all corresponding records
      ArrayList<StateEntry> stateEntries = getStateEntries(stateCode, year);
      for (StateEntry se : stateEntries) {
        se.plantedArea = plantedArea;
      }
    }
  }
}

/*----------------------------------------------------------------------*/
// create and return hashmap containing states coordinates

public HashMap<String, int[]> loadCoordinatesFromCSV(String fileName) {
  coordinatesMap = new HashMap<String, int[]>();

  String[] rows = loadStrings(fileName);
  for (String row : rows) {
    String[] cols = row.split(",");

    if (cols.length >= 4) {
      String stateCode = cols[0];

      int xy[] = new int[2];
      xy[0] = Integer.parseInt(cols[2]);
      xy[1] = Integer.parseInt(cols[3]);

      if (!coordinatesMap.containsKey(stateCode)) {
        coordinatesMap.put(stateCode, xy);
      }
    }
  }
  return coordinatesMap;
}

//////////////////////////////////

class Button {
  boolean pause, play, stop;
  PVector[] pos;
  int d; // diameter of a button
  boolean[] pressed;
  boolean[] mouseOver;
  int counter;

  /*----------------------------*/

  Button(float x, float y) {    
    d = 20;
    pos = new PVector[3];
    pos[0] = new PVector(x - 1.5f*d, y);
    pos[1] = new PVector(x, y);
    pos[2] = new PVector(x + 1.5f*d, y);

    pressed = new boolean[3];
    mouseOver = new boolean[3];
    for (int i = 0; i < pressed.length; i++) {
      pressed[i] = false;
      mouseOver[i] = false;
    }
    counter = 0;
  }

  /*----------------------------*/

  public void applyButton() {
    if (pressed[0]) // pause
      play = false;
    if (pressed[1]) // play
      play = true;
    if (pressed[2]) { // stop
      play = false;  
      thisYear = startYear;
      thisMonth = 1;
      thisViewIdx = getViewIdx(thisMonth, thisYear);
      thisStateEntries = getStateEntries(thisMonth, thisYear);
    }
  }

  /*----------------------------*/
  // if any button is pressed, make pressed true

  public void press(float mx, float my) {
    for (int i = 0; i < pos.length; i++) {
      if (dist(mx, my, pos[i].x, pos[i].y) < d/2) {
        pressed[i] = true;
      }
    }
  }

  /*----------------------------*/
  // make pressed false for each button (used with mouseReleased event)

  public void noPress() {
    for (int i = 0; i < pos.length; i++)
      pressed[i] = false;
  }

  /*----------------------------*/
  // if mouse is over any button, make mouseover true, else false

  public void rollover(float mx, float my) {
    for (int i = 0; i < pos.length; i++) {
      if (dist(mx, my, pos[i].x, pos[i].y) < d/2)
        mouseOver[i] = true;
      else
        mouseOver[i] = false;
    }
  }

  /*----------------------------*/

  public void display() {
    if (play && (counter % 35 == 0)) {
      if (thisViewIdx < Views.length - 1) {
        thisViewIdx++;
      } else {
        thisViewIdx = 0;
      }
      int[] my = getMonthYear(thisViewIdx);
      thisMonth = my[0];
      thisYear = my[1];
      thisStateEntries = getStateEntries(thisMonth, thisYear);
    }
    counter++;

    noStroke();
    // draw button icons according to their status
    for (int i = 0; i < pos.length; i++) {
      if (pressed[i])
        fill(lightPink);
      else if (mouseOver[i])
        fill(lightPink);
      else
        fill(darkGray);
      ellipse(pos[i].x, pos[i].y, d, d);
    }

    fill(255);
    displayPause(pos[0].x, pos[0].y);
    displayPlay(pos[1].x, pos[1].y);
    displayStop(pos[2].x, pos[2].y);
  }

  /*----------------------------*/
  // BUTTON ICONS

  // pause: two vertical lines
  public void displayPause(float x, float y) {
    rectMode(CENTER);
    rect(x-3, y, 4, 9);
    rect(x+3, y, 4, 9);
  }

  // play: a triangle
  public void displayPlay(float x, float y) {   
    triangle(x-3, y-5, x-3, y+5, x+5, y);
  }

  // stop: a sqaure
  public void displayStop(float x, float y) {
    rectMode(CENTER);
    rect(x, y, 9, 9);
  }
}

//////////////////////////////////

class Timeline {
  PVector p0;  // centre of the timeline
  PVector[] pos;  // array of circle positions

  char option; // option to display (years or months)
  int numElements; // number of elements to display
  int midIdx;  // middle element index
  int r;  // circle radius
  int d;  // distance between circles

  Boolean[] mouseOver;
  Boolean[] pressed;  

  /*----------------------------*/

  public Timeline(int x, int y, char option) {
    this.option = option;
    if (option == 'm')
      numElements = 12;
    else if (option == 'y')
      numElements = numYears;

    midIdx = numElements/2;
    r = 6;
    d = 2*r + 40;

    p0 = new PVector(x, y);
    pos = setPosition();

    mouseOver = new Boolean[numElements];
    pressed = new Boolean[numElements];
    for (int i = 0; i < numElements; i++) {
      mouseOver[i] = false;    
      pressed[i] = false;
    }
  }

  /*----------------------------*/
  // set position of each circle

  public PVector[] setPosition() {
    PVector[] p = new PVector[numElements];

    for (int i = midIdx; i >= 0; i--)
      p[i] = new PVector(p0.x - (midIdx - i)*d, p0.y);    

    for (int i = midIdx + 1; i < numElements; i++)  
      p[i] = new PVector(p0.x + (i - midIdx)*d, p0.y);

    return p;
  }

  /*----------------------------*/
  // if mouse is over any button, make mouseover true or false

  public void rollover(float mx, float my) {
    for (int i = 0; i < numElements; i++) {
      if (dist(mx, my, pos[i].x, pos[i].y) < r)
        mouseOver[i] = true;
      else
        mouseOver[i] = false;
    }
  }

  /*----------------------------*/
  // if any button is pressed, make pressed true and update view variables

  public void press(float mx, float my) {
    for (int i = 0; i < numElements; i++)
      if (dist(mx, my, pos[i].x, pos[i].y) < r) {
        pressed[i] = true;
        if (option == 'y')
          thisYear = startYear + i;
        else if (option == 'm')
          thisMonth = startMonth + i;
        thisViewIdx = getViewIdx(thisMonth, thisYear);
        thisStateEntries = getStateEntries(thisMonth, thisYear);
      }
  }

  /*----------------------------*/
  // make pressed false for each button (used with mouseReleased event)

  public void noPress() {
    for (int i = 0; i < numElements; i++)
      pressed[i] = false;
  }

  /*----------------------------*/

  public void display() {        
    int thisElementIdx = thisYear - startYear;

    if (option == 'm') {
      thisElementIdx = thisMonth - 1;
    }

    // draw line
    strokeWeight(2);
    stroke(darkGray);
    line(pos[0].x, pos[0].y, pos[numElements-1].x, pos[numElements-1].y); 

    // draw circles
    strokeWeight(4);
    for (int i = 0; i < numElements; i++) {
      if (thisElementIdx == i) {
        stroke(darkGray);    
        fill(lightPink);
      } else if (mouseOver[i]) {   
        stroke(lightPink);    
        fill(255);
      } else {   
        stroke(darkGray);    
        fill(255);
      }
      ellipse(pos[i].x, pos[i].y, 2*r, 2*r);
    } 

    textAlign(CENTER);
    textSize(14);
    fill(darkGray);
    // draw text (years)
    if (option == 'y') {
      for (int i = 0; i < numElements; i++)    
        if (mouseOver[i])
          text(2006+i, pos[i].x, pos[i].y - 2*r);  

      text(startYear, pos[0].x, pos[0].y + 3*r); 
      text(midYear, pos[midIdx].x, pos[midIdx].y + 3*r);  
      text(endYear, pos[numElements-1].x, pos[numElements-1].y + 3*r);
    } else if (option == 'm') {
      for (int i = 0; i < numElements; i++)    
        text(nameOfMonths[i].substring(0, 3), pos[i].x, pos[i].y + 3*r);
    }
  }
}

//////////////////////////////////

class StateEntry {
  String stateCode;
  String stateName;
  int month;
  int year;
  int numOfFires;
  int transparency;
  int plantedArea;
}
  public void settings() {  fullScreen(P2D);  smooth(8); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--stop-color=#cccccc", "brazilian_fires" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
