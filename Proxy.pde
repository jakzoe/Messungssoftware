class Proxy {

  Serial myPort;

  // empfangene Daten
  String prevPortStream, portStream = "";
  /* wie viele Sensorwerte bereits empfangen wurden
   (counter == werte.length ? => counter == 0; messdurchgang++;) */
  int dataCounter = 1;

  // Variablenwerte einmalig über den Serial-Bus an den Arduino senden
  boolean dataSend = true; // false: currently disabled
  // den ersten messdurchgang ignorieren, da sonst vielleicht nicht alle Messwerte aufgezeichnet werden
  boolean ignoredFirst = false;
  // der letzte Wert, der empfangen wurde (index aus NAMES)
  int lastIndex = -1;

  Proxy() {

    try {
      myPort = new Serial(MAIN, Serial.list()[0], 1200);
      myPort.bufferUntil('\n');
      myPort.clear();
    }
    catch(IndexOutOfBoundsException e) {
      println("Bitte das Kabel des Arduinos einstecken!");
    }
  }

  void update() {

    if (myPort == null) {
      try {
        myPort = new Serial(MAIN, Serial.list()[0], 1200);
        myPort.bufferUntil('\n');
        myPort.clear();
      }
      catch(IndexOutOfBoundsException e) {
        return;
      }
    }

    if (!dataSend && millis() > 3000) {
      dataSend = true;
    }

    // neues serialEvent (siehe serialEvent())
    if (portStream.length() <= 2 || portStream.equals(prevPortStream)) {
      return;
    }
    //portStream = portStream.trim();
    println(portStream);
    prevPortStream = portStream;

    // Ein Daten-Set wurde empfangen
    if (dataCounter >= werte.length) {

      dataCounter = 0;

      /* bevor examples.add(werte.clone()), sonst ergibt das K-NN keinen Sinn,
       da das Ergenmis bereits in den prev_examples wäre */

      //resultScreen.update(werte.clone());
      // update max values
      //for (int i = 0; i < examples.size(); i++) {
      //  for (int j = 0; j < examples.get(i).length; j++) {
      //    if (examples.get(i)[j] > maxValues[j]) {
      //      maxValues[j] = examples.get(i)[j];
      //    }
      //  }
      //}


      // wenn start-Messung Button aktiviert wurde
      if (started) {
        if (!ignoredFirst) {
          ignoredFirst = true;
          return;
        }
        examples.add(werte.clone());
        labels.add(labelList.getLabel());
      }
      //println(started);
      messdurchgang++;
      println("messdurchgang: " + messdurchgang);
    }

    // Sensorwert empfangenn
    if (portStream.split(" ").length == 2) {

      String name = portStream.split(" ")[0];
      float wert = float(portStream.split(" ")[1].trim());

      // ändert sich meist mit Zunahme der Zeit, wird deshalb für die "werte" ignoriert
      //if (name.equals("Temperatur")) {
      //  temp = wert;
      //  lastIndex = NAMES.length-1;
      //  barChart.redraw();
      //  setLaserConstants.redraw();
      //  return;
      //}

      int index = getElement(name);
      if (index != -1) {
        werte[index] = wert;
        if (wert > maxValues[index]) {
          maxValues[index] = wert;
        }
        dataCounter++;
        lastIndex = index;
        barChart.redraw();
        setLaserConstants.redraw();

        if (DEBUG) {
          //println("Debug", NAMES[index], werte[index]);
        }
      }
      // Counter empfangen
    } else if (DEBUG && portStream.split(" ").length == 3) {

      String name = portStream.split(" ")[0];
      int val = int(portStream.split(" ")[2].trim());
      if (name.equals("loopCounter") && val != messdurchgang) {
        if (val-messdurchgang == 1)
          println("Eine messdurchgang ist verloren gegangen! " + messdurchgang);
        else
          println(val-messdurchgang + " Messdurchgänge sind verloren gegangen!", val, messdurchgang);
      }
    }
  }


  int getElement(String name) {
    for (int i = 0; i < werte.length; i++) {
      if (NAMES[i].equals(name)) {
        return i;
      }
    }
    return -1;
  }

  void serialEvent(Serial myPort) {
    portStream = myPort.readString().trim();

    if (portStream.equals("Starting reading of sensors")) {
      surface.setVisible(true);
      for (Window w : APPLETS) {
        w.getSurface().setVisible(true);
      }
    }
  }
}
