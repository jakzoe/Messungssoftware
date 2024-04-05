/*
 * @date 08.01.2024
 * starte die Software mit
 * export _JAVA_OPTIONS=-Djava.io.tmpdir=$XDG_RUNTIME_DIR
 * falls der Fehler "UnsatisfiedLinkError: Could not load the jssc library: Couldn't load library library jssc" angezeigt wird.
 * (jssc wird von dem processing.serial Package verewndet).
 */

import java.net.ServerSocket;
import java.net.Socket;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import processing.serial.*;

// Pointer für Serial
final PApplet MAIN = this;
final Functions F = new Functions();

final BarChart barChart = new BarChart();
final LineChart lineChart = new LineChart();

// damit man alle auf einmal freezen/deFreezen kann
final Window[] APPLETS = new Window[]{
  barChart,
  lineChart,
};

//für Paths
final char SLASH = System.getProperty("os.name").toLowerCase().contains("win") ?  '\\' : '/';

// werden in setup() geladen, da sketchPath() erst dann verfügbar ist
String EXAMPLES_FILE;
String LABELS_FILE;
String CLASS_NAMES_FILE;

// files, von denen vor dem Überschreiben ein Backup erstellt werden soll
String[] BACKUP_FILES;

Encoder examplesEncoder, weightsEncoder;

// hard-coded, eins könnte es aber auch den Arduino senden lassen.
final String[] NAMES = {
  "(405-425nm)",
  "(435-455nm)",
  "(470-490nm)",
  "(505-525nm)",
  "(545-565nm)",
  "(580-600nm)",
  "(620-640nm)",
  "(670-690nm)",
  "Clear",
  "NIR",
};

// Werte der Sensoren
float[] werte = new float[NAMES.length];
// die höchsten Werte der Sensoren, die jemals gemessen wurden
float[] maxValues = new float[werte.length];
// Werte für BoxPlot
float[][][] boxPlot;

// bereits gesammelte Beispiele, ist eine Liste von "werte" Arrays
ArrayList<float[]> examples;
// die dazu gehörenden Labels
ArrayList<String> labels;
// alle Gerüche, die bereits gemessen wurden
ArrayList<String> classNames;
// Anzahl der bereits empfangenen Werte-Sets
int messdurchgang = 0;
// seit wann die (jetzige) Messung läuft
int savedDurchgaenge;

final PVector BUTTON_SIZE = new PVector(100, 70);
color startColor = color(0, 255, 0);
Button startButton;
color lineChartColor = color(189, 212, 255);
Button lineChartButton;
color barChartColor = color(189, 212, 255);
Button barChartButton;
// den jetzigen Messwert löschen
Button deleteButton;

final color TEXT_COLOR = color(100);
color[] chartColors;

boolean started = false;
boolean killThreads = false;

Proxy proxy;
LabelList labelList;

final boolean DEBUG = true;

void settings() {
  size(int(displayWidth/2.03), int(displayHeight/3));
}

void setup() {

  frameRate(30);
  surface.setResizable(true);
  surface.setLocation(int(displayWidth/2-width/2+(Window.OFFSET_X*displayWidth/2  * -1)), int(displayHeight/2-height/2+(Window.OFFSET_Y*displayHeight/2  * -1)));
  if (!DEBUG) {
    // erst starten, wenn der Arduino Daten sendet
    surface.setVisible(false);
  }
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  textSize(22);

  // Laden von nötigen Ressourcen //

  CLASS_NAMES_FILE = getPath("Lasermessung_classNames.txt");
  EXAMPLES_FILE = getPath("Lasermessung_examples.bin");
  LABELS_FILE = getPath("labels.txt");

  BACKUP_FILES = new String[]{
    CLASS_NAMES_FILE,
    EXAMPLES_FILE,
    LABELS_FILE,
  };

  examplesEncoder = new Encoder(EXAMPLES_FILE);

  examples = new ArrayList<float[]>();
  labels = new ArrayList<String>();
  classNames = new ArrayList<String>();

  try {
    examples = F.toFloatList(examplesEncoder.load());
    println("available examples:", examples.size());
  }
  catch(Exception e) {
    e.printStackTrace();
    println("missing file " + EXAMPLES_FILE);
  }

  labels = F.toStringList(loadStrings(LABELS_FILE));

  if (labels.size() == 0) {
    println("missing file " + LABELS_FILE);
  }

  classNames = F.toStringList(loadStrings(CLASS_NAMES_FILE));

  if (classNames.size() == 0) {
    println("missing file " + CLASS_NAMES_FILE);
  }

  wrongExamples = F.toStringList(loadStrings("wrongExamples"));

  if (wrongExamples != null) {
    wrongExamples = new ArrayList<String>();
  }

  // update max values
  for (int i = 0; i < examples.size(); i++) {
    for (int j = 0; j < examples.get(i).length; j++) {
      if (examples.get(i)[j] > maxValues[j]) {
        maxValues[j] = examples.get(i)[j];
      }
    }
  }

  if (DEBUG && examples.size() != 0) {
    // damit etwas gezeigt wird
    // int random = int(random(examples.size()));
    for (int i = 0; i < werte.length; i++) {
      werte[i] = examples.get(examples.size()-1)[i];
    }
  } else {
    savedDurchgaenge = examples.size();
  }


  boxPlot = new float[classNames.size()][werte.length][];

  for (int i = 0; i < boxPlot.length; i++) {

    ArrayList<float[]> allLabelValues = new  ArrayList<float[]>();
    for (int j = 0; j < examples.size(); j++) {
      if (labels.get(j).equals(classNames.get(i))) {
        allLabelValues.add(examples.get(j));
      }
    }

    if (allLabelValues.size() == 0) {
      continue;
    }

    // für jeden Sensor
    for (int j = 0; j < werte.length; j++) {
      float[] sensorVals = new float[allLabelValues.size()];
      for (int k = 0; k < sensorVals.length; k++) {
        sensorVals[k] = allLabelValues.get(k)[j];
      }
      boxPlot[i][j] = calculateBoxPlot(sensorVals);
    }
  }

  chartColors = new color[werte.length];
  //for (int i = 0; i < chartColors.length; i++) {
  //  int r = int(random(255));
  //  int g = int(random(255));
  //  int b = int(random(255));
  //  int a = 200;
  //  chartColors[i] = color(r, g, b, a);
  //}

  //int stagesPerColor = ceil((float)Math.pow(chartColors.length, 1.0/3));
  //int stageSize = 256/stagesPerColor;

  //for (int i = 0; i < chartColors.length; i++) {

  //  // weightsEncoder nur, weil ich value2Base nicht als static deklarieren kann
  //  String indices = weightsEncoder.value2Base(i, stagesPerColor, 3);

  //  int r = int(stageSize*(1+int(str(indices.charAt(0)))));
  //  int g = int(stageSize*(1+int(str(indices.charAt(1)))));
  //  int b = int(stageSize*(1+int(str(indices.charAt(2)))));
  //  int a = 200; // konstant ist besser
  //  chartColors[i] = color(r, g, b, a);
  //}
  chartColors[0] = color(126, 0, 219); // 410nm
  chartColors[1] = color(0, 0, 255); // 440nm
  chartColors[2] = color(0, 213, 255); // 480nm
  chartColors[3] = color(0, 255, 0); // 510nm
  chartColors[4] = color(163, 255, 0); // 550nm
  chartColors[5] = color(255, 223, 0); // 590nm
  chartColors[6] = color(255, 79, 0); // 630nm
  chartColors[7] = color(223, 0, 0); // 680nm
  chartColors[8] = color(50, 50, 50); // Clear
  chartColors[9] = color(150, 150, 150); // NIR


  // braucht height Variable, die erst mit size() festgelegt wurde
  labelList = new LabelList();

  startButton = new Button(
    width/1.3, height/5,
    BUTTON_SIZE.x, BUTTON_SIZE.y,
    (self) -> {
    if (labelList.getLabel() == null) {
      return;
    }
    if (started) {
      startColor = color(0, 255, 0);
      stop();
      startColor = color(255, 0, 0);
      savedDurchgaenge = examples.size();
      proxy.ignoredFirst = false;
    }
  }
  ,
    (self) -> {
    fill(startColor);
    // stroke(0);
    noStroke();
    rect(self.pos.x, self.pos.y, self.size.x, self.size.y);
    textSize(24);
    fill(30);
    text(started ? "STOP" : "Start", self.pos.x, self.pos.y);
    textSize(20);
    fill(TEXT_COLOR);
    text(started ? "" : "Select a label", self.pos.x, self.pos.y+self.size.y/1.6);
  }
  );

  lineChartButton = new Button(
    width/1.3, height/2,
    BUTTON_SIZE.x, BUTTON_SIZE.y,
    (self) -> {

    if (lineChart.freezed) {
      lineChart.deFreeze();
      lineChartColor =  color(189, 212, 255);
    } else {
      lineChart.freeze();
      lineChartColor = color(0, 255, 0);
    }
  }
  ,
    (self) -> {
    fill(lineChartColor);
    // stroke(0);
    noStroke();
    rect(self.pos.x, self.pos.y, self.size.x, self.size.y);
    textSize(24);
    fill(30);
    text(lineChart.freezed ? "show" : "hide", self.pos.x, self.pos.y);
    textSize(20);
    fill(TEXT_COLOR);
    text((lineChart.freezed ? "show" : "hide") + " line-chart", self.pos.x, self.pos.y+self.size.y/1.6);
  }
  );

  barChartButton = new Button(
    width/1.3, height/1.2,
    BUTTON_SIZE.x, BUTTON_SIZE.y,
    (self) -> {

    if (barChart.freezed) {
      barChart.deFreeze();
      barChartColor =  color(189, 212, 255);
    } else {
      barChart.freeze();
      barChartColor = color(0, 255, 0);
    }
  }
  ,
    (self) -> {
    fill(barChartColor);
    // stroke(0);
    noStroke();
    rect(self.pos.x, self.pos.y, self.size.x, self.size.y);
    textSize(24);
    fill(30);
    text(barChart.freezed ? "show" : "hide", self.pos.x, self.pos.y);
    textSize(20);
    fill(TEXT_COLOR);
    text((barChart.freezed ? "show" : "hide") + " bar-chart", self.pos.x, self.pos.y + self.size.y/1.6);
  }
  );


  deleteButton = new Button(
    width/1.1, height/2,
    BUTTON_SIZE.x, BUTTON_SIZE.y,
    (self) -> {

    // delete
    println("test delete");

    wrongExamples.add(str(resultExampleIndex));
  }
  ,
    (self) -> {
    fill(lineChartColor);
    // stroke(0);
    noStroke();
    rect(self.pos.x, self.pos.y, self.size.x, self.size.y);
    textSize(24);
    fill(30);
    text("X", self.pos.x, self.pos.y);
    textSize(20);
    fill(TEXT_COLOR);
    text("remove", self.pos.x, self.pos.y+self.size.y/1.6);
  }
  );

  proxy = new Proxy();

  for (Window w : APPLETS) {
    w.deFreeze();
  }

  new Thread(()-> {
    while (!killThreads) {
      proxy.update();
    }
  }
  ).start();

  thread("runServer");
}

// one-hot encoding
float[][] getLabelsOneHot() {

  float[][] oneHot = new float[labels.size()][classNames.size()];

  for (int i = 0; i < labels.size(); i++) {
    int label = classNames.indexOf(labels.get(i));
    oneHot[i][label] = 1;
  }
  return oneHot;
}

void draw() {

  background(255);

  startButton.show();
  barChartButton.show();
  lineChartButton.show();
  deleteButton.show();

  labelList.show();

  if (DEBUG) {
    textSize(15);
    fill(60);
    text("Debug Mode", width/2, height-20);
  }
}


// wird von dem STOPP Button aufgerufen
void stop() {

  started = false;

  if (DEBUG) {
    return;
  }

  // backup //
  String time =   "_" + year() + "_" + month() +  "_" + hour() +  "_"  + minute() +  "_"  + second();

  for (int i = 0; i < BACKUP_FILES.length; i++) {

    Path source = Paths.get(BACKUP_FILES[i]);
    Path target = Paths.get(BACKUP_FILES[i] + time);
    try {
      Files.copy(source, target);
    }
    catch (IOException e) {
      e.printStackTrace();
      println("Einige Backups konnten nicht erstellt werden!!!");
    }
  }

  lineChart.save(getPath(labelList.getLabel() + "_lines.jpg"));
  barChart.save(getPath(labelList.getLabel() + "_bars.jpg"));

  examplesEncoder.save(F.toFloatArray(examples));
  saveStrings(LABELS_FILE, F.toStringArray(labels));
  saveStrings(CLASS_NAMES_FILE, F.toStringArray(classNames));


  Table table = new Table();

  table.addColumn("Durchgang");
  for (int i = 0; i < NAMES.length; i++) {
    table.addColumn(NAMES[i]);
  }

  for (int i = 0; i < examples.size(); i++) {
    TableRow newRow = table.addRow();
    newRow.setInt("Durchgang", i);
    for (int j = 0; j < NAMES.length; j++) {
      newRow.setFloat(NAMES[j], examples.get(i)[j]);
    }
  }
  saveTable(table, getPath(labelList.getLabel() + ".csv"));
}

// alle Rechtecke per default mit abgerundeten Ecken, einfach da es moderner aussieht
final int CORNER_RADIUS = 8;

@Override
  void rect(float x, float y, float sx, float sy) {
  rect(x, y, sx, sy, CORNER_RADIUS, CORNER_RADIUS, CORNER_RADIUS, CORNER_RADIUS);
}

@Override
  void exit() {
  killThreads = true;
  saveStrings("wrongExamples", F.toStringArray(wrongExamples));
}

@Override
  void mouseReleased() {
  barChart.redraw();
}


// wird von Serial aufgerufen, wenn: buffer = data + -> \n <-
void serialEvent(Serial myPort) {
  proxy.serialEvent(myPort);
}

// kann wgen sketchPath() erst ab setup() aufgerufen werden
String getPath (String name) {
  return sketchPath("data" + SLASH + name);
}

void exitError(Exception e, String message) {

  e.printStackTrace();
  println(message);
  noLoop();
}

void exitError(Exception e, String message, boolean exit) {

  exitError(e, message);
  if (exit)
    System.exit(0);
}

float skaliere(float oldVal, float oldMax, float newMax) {
  return newMax * (oldVal / oldMax);
}


float[] calculateBoxPlot(float[] originalData) {

  float[] data = sort(originalData);

  float q1 = calculateQuartile(data, 0.25);
  float q2 = calculateQuartile(data, 0.5);
  float q3 = calculateQuartile(data, 0.75);

  float iqr = q3 - q1;

  float lowerFence = q1 - 1.5 * iqr;
  float upperFence = q3 + 1.5 * iqr;

  float mean = 0;
  for (int i = 0; i < originalData.length; i++) {
    mean += originalData[i];
  }
  mean /= originalData.length;

  return new float[]{lowerFence, q1, q2, q3, upperFence, mean};
}

public static float calculateQuartile(float[] data, float percentile) {

  float index = percentile * (data.length + 1);
  int lower = (int) floor(index);
  int upper = (int) ceil(index);
  float fraction = index - lower;

  if (lower == 0 || upper >= data.length) {
    return data[lower];
  } else {
    return data[lower] + fraction * (data[upper] - data[lower]);
  }
}

void drawDashedLine(float x1, float y1, float x2, float y2, float dashLength, float gapLength) {

  float distance = dist(x1, y1, x2, y2); // Entfernung zwischen den Punkten berechnen
  float dashCount = distance / (dashLength + gapLength); // Anzahl der Striche berechnen

  float dashX = (x2 - x1) / dashCount; // X-Abstand pro Strich
  float dashY = (y2 - y1) / dashCount; // Y-Abstand pro Strich

  float currentX = x1;
  float currentY = y1;

  for (int i = 0; i < dashCount; i++) {
    if (i % 2 == 0) {
      // Strich zeichnen
      line(currentX, currentY, currentX + dashX, currentY + dashY);
    }

    // Aktuelle Position aktualisieren
    currentX += dashX;
    currentY += dashY;
  }
}


// float[] absorption = {100, 150, 200, 10, 10, 10, 100, 200};

color colorFromAbsorption(float[] absorptioncopy) {

  float[] absorption = absorptioncopy.clone();

  //float[] absorption = {255, 255, 255, 255, 255, 255, 255, 255};
  //float[] absorption = {100, 100, 100, 105, 100, 100, 100, 100};
  //float[] absorption = {0, 0, 0, 0, 0, 0, 0, 0};
  //float[] absorption = {100, 100, 255, 255, 255, 255, 0, 0};
  //float[] absorption = {100, 150, 200, 10, 10, 10, 100, 200};

  // NaN verhindern, falls durch Null geteilt wird.
  float offset = 0.0001;

  float maxVal = max(absorption) + offset;

  for (int i = 0; i < absorption.length; i++) {
    absorption[i] += offset;
    absorption[i] /= maxVal;
  }

  float totalR = 0;
  float totalG = 0;
  float totalB = 0;

  for (int i = 0; i < absorption.length; i++) {

    totalR += red(chartColors[i]) * absorption[i];
    totalG += green(chartColors[i]) * absorption[i];
    totalB += blue(chartColors[i]) * absorption[i];
  }

  totalR /= absorption.length;
  totalG /= absorption.length;
  totalB /= absorption.length;

  // set brightness to lowest at all times
  //  maxVal = max(totalR, totalG, totalB);
  //  totalR /= maxVal/255;
  //  totalG /= maxVal/255;
  //  totalB /= maxVal/255;

  // inverse
  totalR = 255 - totalR;
  totalG = 255 - totalG;
  totalB = 255 - totalB;

  //print(totalR, totalG, totalB);

  return color(totalR, totalG, totalB);
}


void runServer() {

  try {

    ServerSocket server = new ServerSocket(8080);

    Socket client = server.accept();

    BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
    PrintWriter out = new PrintWriter(client.getOutputStream(), true);
    String receivedString = "";

    while (!receivedString.equals("terminate")) {

      receivedString = in.readLine();
      if (receivedString == null)
        receivedString = "";
      else
        println(receivedString);
      out.println("send data from server");
    }

    out.close();
    in.close();
    client.close();
    server.close();
  }
  catch(IOException e) {
    e.printStackTrace();
  }
}
