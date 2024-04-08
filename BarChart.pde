class BarChart extends Window {

  int len, w;
  color oldCol = color(0, 0, 0);

  volatile PImage overlay;

  @Override
    void setup() {

    surface.setTitle("Jetzige Messwerte");
    surface.setResizable(true);
    setLocation(-1, 1);
    if (!DEBUG) {
      // erst starten, wenn der Arduino Daten sendet
      surface.setVisible(false);
    }
    noLoop();
    textSize(16);
    len = NAMES.length;
    w = width/2/len;
  }

  @Override
    void draw() {

    if (overlay != null) {
      image(overlay, 0, 0);
      return;
    }

    background(250);

    // stroke(50);
    noStroke();

    for (int i = 0; i < len; i++) {
      fill(chartColors[i]);
      rect(width/len*i+w/2, height, w, -int(skaliere(werte[i], maxValues[i], height)));
    }
    //printArray(werte);
    //printArray(maxValues);

    int smellIndex = classNames.indexOf(labelList.getLabel());
    if (smellIndex >= 0 && smellIndex < boxPlot.length) {
      for (int i = 0; i < len; i++) {
        float[] boxPlotValues = boxPlot[smellIndex][i];

        fill(255, 0, 0);
        float meanValue = int(skaliere(boxPlotValues[5], maxValues[i], height));
        rect(width/len*i+w/2, height-meanValue+1, w, 1);


        fill(155, 0, 0);
        float median = int(skaliere(boxPlotValues[2], maxValues[i], height));
        rect(width/len*i+w/2, height-median+3, w, 3);

        //strokeWeight(2);
        //stroke(0);
        //strokeCap(SQUARE); // Linienabschluss auf "SQUARE" setzen für gestrichelte Linie
        //drawDashedLine(50, 100, 350, 200, 10, 5); // Startpunkt (50, 200), Endpunkt (350, 200), Strichlänge 10, Lückenlänge
        //noStroke();


        fill(0, 255, 0, 100);
        float q1 = int(skaliere(boxPlotValues[1], maxValues[i], height));
        float q3 = int(skaliere(boxPlotValues[3], maxValues[i], height));
        rect(width/len*i+w/2, height-q3, w, abs(q3-q1));
      }
    }

    noStroke();
    textAlign(CENTER, CENTER);
    fill(10);

    for (int i = 0; i < len; i++) {
      // um zu wissen, welcher Wert gerade empfangen wurde
      if (i == proxy.lastIndex) {
        textSize(20);
      } else {
        textSize(14);
      }
      text(NAMES[i], width/len*i+w, height-30);
    }

    textSize(14);
    text("messdurchgang: " + ( examples.size()-savedDurchgaenge), width/2-textWidth("messdurchgang: ")/2, 50);

    if (proxy.dataCounter == werte.length) {
      fill(oldCol = colorFromAbsorption(werte));
    } else
      fill(oldCol);

    noStroke();
    rect(width/1.1, height/10, 20, 20);

    fill(50);

    // 1/6
    text(100/6 + " %", 20, height - height/6);
    // 2/6
    text(200/6 + " %", 20, height - height/3);
    // 3/6
    text(300/6 + " %", 20, height/2);
    // 4/6
    text(400/6 + " %", 20, height - 2*height/3);
    // 5/6
    text(500/6 + " %", 20, height - 5*height/6);

    stroke(100);
    strokeWeight(1);
    // 1/6
    line(40, height - height/6, width, height - height/6);
    // 2/6
    line(40, height - height/3, width, height - height/3);
    // 3/6
    line(40, height/2, width, height/2);
    // 4/6
    line(40, height - 2*height/3, width, height - 2*height/3);
    // 5/6
    line(40, height - 5*height/6, width, height - 5*height/6);
  }


  void applyPlot(color[] plotPixels) {
    overlay = createImage(width, height, RGB);
    overlay.loadPixels();

    int iterator = 0;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        overlay.pixels[x + y * width] = plotPixels[iterator];
        iterator++;
      }
    }
    overlay.updatePixels();
  }

  void setFrameSize(int x, int y) {
    windowResize(x, y);
  }

  void mousePressed() {
    if (overlay == null)return;
    println(overlay.get(mouseX, mouseY));
  }
}
