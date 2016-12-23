import java.util.*;
import java.text.DecimalFormat;
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.geo.*;

// variables
int scrX, scrY;
Table votes;
HashMap<String, ArrayList<Vote>> votehash;
ArrayList<String> votedates;
int t;
boolean play;
boolean prevplay;
String[] voteTypes;
int[] voteChartData;
int factor;
int xOffset, yOffset;
// map
UnfoldingMap map;
HashMap<String, DataEntry> dataEntriesMap;
List<Marker> countryMarkers;
// 1 = map, 2 = barchart
int screen;
// buttons for changing screens
ArrayList<Button> buttons;
// event dispatcher
String tooltip;
// format numbers with commas
DecimalFormat df;
int tcs; // total countries selected
HashMap<String, String> fullNameHash;


// setup
void setup() {
  size(1000, 700);
  smooth();
  colorMode(HSB, 360, 100, 100);
  screen = 1;
  tooltip = "";
  df = new DecimalFormat("#,###");
  tcs = 0;
  textAlign(CENTER);
  fullNameHash = new HashMap<String, String>();
  loadFullNames();
  
  //// setup buttons
  buttons = new ArrayList<Button>();
  int y = height/2 - 30;
  buttons.add(new Button(0, "Number of Users", 45, y));
  buttons.add(new Button(1, "Upvote/Downvote Ratio", buttons.get(0).right(), y));
  buttons.add(new Button(2, "Average Reputation", buttons.get(1).right(), y));
  buttons.add(new Button(3, "Total Upvotes", buttons.get(2).right(), y));
  buttons.add(new Button(4, "Total Downvotes", buttons.get(3).right(), y));
  buttons.add(new Button(5, "Total Reputation", buttons.get(4).right(), y));
  // select first button
  buttons.get(0).selected = true;
  // deselect all
  buttons.add(new Button(-1, "Clear Selection", 45, 10));
  
  //// setup map
  map = new UnfoldingMap(this, 0, 0, width, height/2);
  //map.mapDisplay.setProvider(null);
  map.zoomAndPanTo(new Location(27f, 17f), 2);
  map.setZoomRange(1,5);
  map.setBackgroundColor(color(0,0,100));
  MapUtils.createDefaultEventDispatcher(this, map);

  // Load country polygons and adds them as markers
  List<Feature> countries = GeoJSONReader.loadData(this, "countries.geo.json");
  countryMarkers = MapUtils.createSimpleMarkers(countries);
  map.addMarkers(countryMarkers);

  // Load population data
  dataEntriesMap = loadPopulationDensityFromCSV("countrydata2.csv");
  println("Loaded " + dataEntriesMap.size() + " data entries");

  // Country markers are shaded according to its population density (only once)
  // 0 numusers 519786, 1 ratio 1074, 2 avgrep 7649
  // 3 totup 2818198, 4 totdown 217257, 5 totrep 26992846
  shadeByIndex(0);
  
  //// setup barcharts
  t = 0;
  frameRate(15);
  factor = 300;
  voteTypes = new String[]{"Accepted", "UpMod", "DownMod", "Offensive", "Favorite", "Close", "Reopen", "BountyStart", "BountyClose", "Undeletion", "Deletion", "Spam", "Report"};
  voteChartData = new int[13];
  // load users
  loadVotes();
  play = true;
}

// draw loop
void draw() {
  
  // draw map
  // Draw map tiles and country markers
  if (screen == 1) {
    background(0,0,100);
    map.updateMap();
    for (Marker marker: countryMarkers) {
      marker.draw(map);
    }
    if (tooltip.length() > 0) {
      fill(0,0,100,200);
      noStroke();
      textSize(32);
      rect((width - textWidth(tooltip))/2 - 2, 6, textWidth(tooltip) + 4, 36, 8);
      fill(0);
      text(tooltip, width/2, 36);
    }
    
    // draw buttons
    for (Button b: buttons) {
      b.draw();
    }
  }
  
  // draw barchart
  noStroke();
  fill(0,0,100);
  rect(0, height/2, width, height);
  float x, y;
  fill(0,70,0);
  updateBarchart();
  int barwidth = width / 13;
  int startx, stopx, starty, stopy;
  stopy = height;
  // draw bars
  textSize(18);
  for (int i = 0; i < 13; i++) {
    startx = i * barwidth;
    stopx = startx + barwidth;
    starty = max(stopy - voteChartData[i] * 50 / factor, height/2);
    if (starty == height/2) {
      fill(31,80,100);
    } else {
      fill(31,100,100);
    }
    rect(startx + 1, starty, stopx - startx - 2, stopy - starty);
  }
  fill(0);
  for (int i = 0; i < 13; i++) {
    startx = i * barwidth;
    stopx = startx + barwidth;
    starty = max(stopy - voteChartData[i] * 50 / factor, height/2);
    fill(0);
    pushMatrix();
    translate((startx + stopx) / 2, stopy - 20);
    rotate(-0.25);
    text(voteTypes[i], 0, 0);
    popMatrix();
  }
  // draw title
  textSize(32);
  fill(0);
  text("20" + votedates.get(t), width / 2, height/2 + 50);
  // draw height values
  textSize(16);
  stroke(0, 100);
  fill(0, 150);
  for (int i = 50; i < height/2 - 50; i += 50) {
    int iy = height - i;
    line(0, iy, width, iy);
    text(df.format(i * factor / 50), width / 2, iy - 2);
  }
  line(0, height/2, width, height/2);
  noStroke();
  if (play) {
    fill(130,50,80);
    triangle(width - 80, height/2 + 18, width - 40, height/2 + 40,
      width - 80, height/2 + 62);
  }
  else {
    fill(0,50,100);
    rect(width - 80, height/2 + 20, 10, 40);
    rect(width - 60, height/2 + 20, 10, 40);
  }
}

void mouseWheel(MouseEvent event) {
  if (screen == 2) {
    int v = 1;
    if (event.getAmount() > 0) {
      if (factor >= 500) {
        v = 100;
      }
      else if (factor >= 50) {
        v = 50;
      }
      else if (factor >= 10) {
        v = 5;
      }
    } else {
      if (factor <= 10) {
        v = 1;
      }
      else if (factor <= 50) {
        v = 5;
      }
      else if (factor <= 500) {
        v = 50;
      }
      else {
        v = 100;
      }
    }
    factor += event.getAmount() * v;
    if (factor < 1) {
      factor = 1;
    } else if (factor > 1000) {
      factor = 1000;
    }
  }
}

void mouseClicked() {
  for (Button b: buttons) {
    if (b.mouseOver()) {
      if (b.value == -1) {
        for (Marker m: map.getMarkers()) {
          if (dataEntriesMap.get(m.getId()) != null) {
            dataEntriesMap.get(m.getId()).selected = false;
            updateMarker(m);
          }
        }
        tcs = 0;
      }
      else {
        shadeByIndex(b.value);
        for (Button u: buttons) {
          u.selected = false;
        }
        b.selected = true;
      }
      return;
    }
  }
  if (screen == 1) {
    Marker marker = map.getFirstHitMarker(mouseX, mouseY);
    DataEntry de;
    if (marker != null) {
      de = dataEntriesMap.get(marker.getId());
      if (de != null) {
        de.selected = !de.selected;
        if (de.selected) {
          tcs++;
        } else {
          tcs--;
        }
        updateMarker(marker);
      }
    }
  }
  else if (screen == 2) {
    play = !play;
  }
}

void mousePressed() {
  if (screen == 2) {
    prevplay = play;
    play = false;
    xOffset = mouseX;
    yOffset = mouseY;
  }
}
void mouseDragged(MouseEvent event) {
  if (screen == 2) {
    int s = 2; // sensitivity
    if (t + (mouseX - xOffset) / s >= 0 && t + (mouseX - xOffset) / s < votedates.size()) {
      t += (mouseX - xOffset) / s;
      xOffset = mouseX;
      yOffset = mouseY;
    }
  }
}
void mouseReleased() {
  if (screen == 2) {
    play = prevplay;
  }
}

void mouseMoved() {
  if (mouseY < height/2) {
    screen = 1;
  } else {
    screen = 2;
  }
  tooltip = "";
  if (screen == 1) {
    Marker marker = map.getFirstHitMarker(mouseX, mouseY);
    DataEntry de;
    if (marker != null) {
      de = dataEntriesMap.get(marker.getId());
      if (de != null) {
        tooltip = fullNameHash.get(marker.getId()) + ": " + df.format(de.value[de.index]);
      } else if (fullNameHash.get(marker.getId()) != null) {
        tooltip = fullNameHash.get(marker.getId()) + ": No Data";
      } else {
        tooltip = "No Data";
      }
    }
    for (Marker m: map.getMarkers()) {
      updateMarker(m);
    }
  }
}

void loadVotes() {
  votehash = new HashMap<String, ArrayList<Vote>>();
  String[] lines = loadStrings("votes2.csv");
  for (String l: lines) {
    String[] parsed = split(l, ',');
    String cc = parsed[0];
    Integer vtid = Integer.parseInt(parsed[1]);
    if (vtid > 13) {
      continue;
    }
    String cdate = parsed[2];
    if (votehash.get(cdate) == null) {
      votehash.put(cdate, new ArrayList<Vote>());
    }
    votehash.get(cdate).add(new Vote(cc, vtid));
  }
  votedates = new ArrayList<String>(votehash.keySet());
  //votedates.removeAll(Collections.singleton(null));
  Collections.sort(votedates);
}

void updateBarchart() {
  if (play) {
    t++;
    if (t >= votedates.size()) {
      t = 0;
    }
  }
  for (int i = 0; i < 13; i++) {
    voteChartData[i] = 0;
  }
  for (Vote v: votehash.get(votedates.get(t))) {
    if (tcs == 0 || dataEntriesMap.get(v.cc).selected == true) {
      voteChartData[v.type - 1]++;
    }
  }
}

void shadeByIndex(int i) {
  // 0 numusers 519786, 1 ratio 1074, 2 avgrep 7649
  // 3 totup 2818198, 4 totdown 217257, 5 totrep 26992846
  int mv = 0;
  switch (i) {
    case 0: mv = 37465; break;
    case 1: mv = 1074; break;
    case 2: mv = 7649; break;
    case 3: mv = 2818198; break;
    case 4: mv = 217257; break;
    case 5: mv = 26992846; break;
  }
  shadeCountries(i, mv);
}

void shadeCountries(int index, int maxval) {
  for (Marker marker : countryMarkers) {
    // Find data for country of the current marker
    String countryId = marker.getId();
    DataEntry dataEntry = dataEntriesMap.get(countryId);

    if (dataEntry != null && dataEntry.value != null) {
      dataEntry.index = index;
      dataEntry.maxval = maxval;
      updateMarker(marker);
    } 
    else {
      // No value available
      marker.setColor(color(0,0,70));
    }
  }
}

void updateMarker(Marker m) {
  String countryId = m.getId();
  DataEntry dataEntry = dataEntriesMap.get(countryId);

  if (dataEntry != null && dataEntry.value != null) {
    int col = 211;
    if (dataEntry.selected) {
      col = 31;
    }
    float sat = map(log(max(dataEntry.value[dataEntry.index], 1)), 0, log(dataEntry.maxval), 10, 100);
    m.setColor(color(col, sat, 100));
  } 
  else {
    // No value available
    m.setColor(color(0,0,70));
  }
}

HashMap<String, DataEntry> loadPopulationDensityFromCSV(String fileName) {
  HashMap<String, DataEntry> dataEntriesMap = new HashMap<String, DataEntry>();

  String[] rows = loadStrings(fileName);
  for (String row : rows) {
    // Reads country name and population density value from CSV row
    String[] columns = row.split(",");
    if (columns.length >= 3) {
      DataEntry dataEntry = new DataEntry();
      dataEntry.countryName = columns[0];
      dataEntry.id = columns[0];
      // 1 numusers, 2 ratio, 3 avgrep, 4 totup, 5 totdown, 6 totrep
      dataEntry.value = new Integer[6];
      for (int i = 1; i < 7; i++) {
        dataEntry.value[i-1] = Integer.parseInt(columns[i]);
      }
      dataEntriesMap.put(dataEntry.id, dataEntry);
    }
  }

  return dataEntriesMap;
}

void loadFullNames() {
  Table t = loadTable("country-codes.csv", "header");
  for (TableRow row: t.rows()) {
    fullNameHash.put(row.getString("ISO3166-1-Alpha-3"), row.getString("name"));
  }
}

boolean mouseIn(int x, int y, int wid, int hei) {
  return mouseX >= x && mouseX <= x + wid && mouseY >= y && mouseY <= y + hei;
}

class DataEntry {
  String countryName;
  String id;
  Integer year;
  Integer value[];
  int index;
  int maxval;
  boolean selected;
}

class Vote {
  String cc;
  int type;
  Vote(String countrycode, int votetype) {
    cc = countrycode;
    type = votetype;
  }
}

class Button {
  int x;
  int y;
  int wid;
  int hei;
  String id;
  int value;
  boolean selected;
  
  
  Button(int value, String id, int x, int y) {
    this.x = x;
    this.y = y;
    this.hei = 20;
    textSize(this.hei - 4);
    this.wid = int(textWidth(id) + 4);
    this.value = value;
    this.id = id;
    selected = false;
  }
  
  void draw() {
    textSize(hei - 4);
    // map button
    if (selected || mouseOver()) {
      fill(0, 0, 100, 200);
      stroke(0, 0, 50);
    }
    else {
      fill(0, 0, 100, 150);
      noStroke();
    }
    rect(x, y, wid, hei, 5);
    fill(0);
    text(id, x + wid/2, y + hei - 3);
  }
  
  int right() {
    return x + wid + 10;
  }
  
  boolean mouseOver() {
    return mouseIn(x, y, wid, hei);
  }
}
