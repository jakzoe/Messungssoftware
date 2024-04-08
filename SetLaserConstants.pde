public class SetLaserConstants extends Window {

  TextField[] textFields;

  static final int margin = 20;
  int x, y;
  int sizex, sizey;

  // light oder dark theme
  boolean light = false;
  color textColor = color(0);
  color backgroundColor = color(255);
  color contrast = color(0, 0, 100);

  String[] helpDocumentation;
  String[] networkSettings;

  static final int DATA_TYPE = 0;
  static final int DATA_NAME = 1;
  static final int DATA_VALUE = 2;
  static final int DATA_DEFAULT = 3;
  static final int DATA_OBJECT = 4;

  //der String der in dem Help-Field gezeigt wird
  String helpString = "";


  @Override
    void settings() {
    size(1200, 300); // ,P2D
  }

  @Override
    void setup() {

    surface.setTitle("Alle vergangenen Messwerte");
    surface.setResizable(true);
    setLocation(1, 1);
    //width = 1200;
    //height = 300;
    loop();
    this.surface.setVisible(true);
    freeze();
    deFreeze();

    helpDocumentation = loadStrings(getPath("help.txt"));
    networkSettings = loadStrings(getPath("data.txt"));

    x = width-2*margin;
    y = height-2*margin;
    // 6 Felder für jedes y
    sizex = x/4-margin;
    // 3 Felder für jedes x
    sizey = y/2-margin;

    textFields = new TextField[networkSettings.length];

    for (int i = 0; i < textFields.length; i++) {
      int posx = i*(sizex+margin);
      // dataIndex
      int dI = i;

      textFields[i] = new TextField((posx+margin)%x, (int(posx/x)*(sizey+margin)+margin)%y, sizex, sizey,
        getData(dI, DATA_TYPE), getData(dI, DATA_NAME), getData(dI, DATA_VALUE));
    }

    for (TextField f : textFields)
      f.ignore = false;
  }

  @Override
    void draw() {

    background(backgroundColor);

    for (TextField t : textFields)
      t.show();
  }


  void mouseReleased() {
    for (TextField t : textFields) {
      t.mouseReleased(mouseX, mouseY);
    }
  }

  void keyPressed() {
    for (TextField t : textFields) {
      t.keyPressed();
    }
  }
  void keyReleased() {
    for (TextField t : textFields) {
      t.keyReleased();
    }
  }
  void keyTyped() {
    for (TextField t : textFields) {
      t.keyTyped();
    }
  }


  String getData(int index, int method) {
    return split(networkSettings[index], "|")[method];
  }

  String getData(String name, int method) {

    for (int i = 0; i < networkSettings.length; i++) {
      if (getData(i, DATA_NAME).equals(name))
        return getData(i, method);
    }
    return "";
  }

  String setData(int index, String value, int method) {
    return networkSettings[index].replace(getData(index, method), value);
  }

  String setData(String name, String value, int method) {

    for (int i = 0; i < networkSettings.length; i++) {
      if (getData(i, DATA_NAME).equals(name))
        return setData(i, value, method);
    }
    return "";
  }


  class TextField extends LaserConstantsButton {

    PVector pos, size;
    String userInput = "";
    String name = "";
    //help string wird gezeigt wenn das Feld ausgewählt ist
    String help = "";
    boolean userIsTyping = false;
    String TYPE;
    int writeIndex = 1;
    Object value;
    final int NAME_Y_OFFSET = 5;
    final int VALUE_Y_OFFSET = 15;

    TextField(int px, int py, int sx, int sy, String type, String _name, Object val) {
      super(px+sx/2, py+sy/2, sx, sy);

      this.TYPE = type;
      this.name = _name;
      this.value = val;

      if (TYPE.equals("boolean"))
        value = Boolean.parseBoolean(value.toString());
      else if (TYPE.equals("float") || TYPE.equals("double"))
        writeIndex = userInput.length();

      pos = new PVector(px, py);
      size = new PVector(sx, sy);
      userInput = value.toString();

      textSize(21);
      noFill();

      for (int i = 0; i < helpDocumentation.length; i++) {
        if (split(helpDocumentation[i], ":::")[0].equals(name)) {
          help = split(helpDocumentation[i], ":::")[1];
          break;
        }
      }
    }

    int x, y;
    // ob schon "|" gezeichnet wurde
    boolean cursor;
    // eine Lücke zwischen Buchstaben neben dem Cursor lassen
    boolean withMargin = false;
    // ob die Events ignoriert werden sollen
    boolean ignore = false;
    // für einen Zyklus ignorieren, damit für eine kurze Zeit die Events deaktiviert werden
    boolean tempIgnore = false;

    void show() {

      if (tempIgnore) {
        ignore = false;
        tempIgnore = false;
      }

      if (textWidth(name) < size.x)
        textSize(21);
      else
        textSize(15);

      if (userIsTyping && !helpString.equals(help))
        helpString = help;

      pushMatrix();

      noFill();
      if (light)
        stroke(userIsTyping ? color(250, 200) : color(200, 150));
      else
        stroke(userIsTyping ? color(150, 150) : color(100, 100));

      rectMode(CORNER);
      rect(pos.x, pos.y, size.x, size.y, 5);

      textAlign(LEFT, TOP);

      fill(light ? color(170, 30, 30) : color(255, 100, 100));
      text(name, pos.x + size.x/2-textWidth(name)/2, pos.y+NAME_Y_OFFSET, size.x, size.y);

      fill(206, 39, 44);
      translate(size.x/2-textWidth(userInput)/2, 20+VALUE_Y_OFFSET);

      textSize(21);

      if (TYPE.equals("boolean")) {
        text(userInput, pos.x, pos.y, size.x, size.y);
        popMatrix();
        return;
      }
      /* Input mit Cursor zeigen */

      if (withMargin) {
        x = 0;
        y = 0;
        cursor = false;
        color fadeColor = fade();
        int posx, posy;

        for (int i = 0; i <= userInput.length(); i++) {

          posx = int(pos.x+x%(size.x-10));
          posy = int(pos.y+y);

          // den Cursor zeigen
          if (userIsTyping && !cursor && (i == writeIndex || i == userInput.length())) {
            fill(fadeColor);
            text("|", posx, posy, size.x, size.y);

            if (i != userInput.length()) {
              cursor = true;
              x += textWidth("|");
              posx += textWidth("|");
            }
          }

          if (i == userInput.length())
            continue;

          fill(textColor());
          text(str(userInput.charAt(i)), posx, posy, size.x, size.y);

          x += textWidth(userInput.charAt(i));
          y = int((x/(size.x-10)))*30;
        }
      } else {

        if (userIsTyping) {
          fill(fade());

          String chars;
          if (writeIndex == userInput.length())
            chars = userInput;
          else
            chars = userInput.substring(0, writeIndex);

          x = int(textWidth(chars));
          text("|", pos.x+x-2, pos.y, size.x, size.y);
        }

        textAlign(LEFT, TOP);
        fill(textColor());
        text(userInput, pos.x, pos.y, size.x, size.y);
      }

      popMatrix();
    }

    color textColor() {
      return textColor;
    }


    boolean dark = false;
    int fadeValue = 0;

    int fade() {
      if (keyPressed) {
        fadeValue = 255;
        return fadeValue;
      }

      if (fadeValue <= 40)
        dark = false;
      else if (fadeValue >= 250)
        dark = true;

      if (dark)
        fadeValue -= 8;
      else
        fadeValue += 8;

      return fadeValue;
    }

    // @Override
    void keyTyped() {

      if (!userIsTyping || ignore) return;
      if (textWidth(userInput)+10 >= size.x) {
        checkBackspace();
        return;
      }

      switch(TYPE) {
      case "long":
      case "int":
      case "char":
      case "byte":
        //vieleicht und dass der Wert nicht zu groß ist=
        if (key >= '0' && key <= '9') {
          addChar();
        }
        break;

      case "double":
      case "float":
        if (((key >= '0' && key <= '9') || key == '.')) {
          addChar();
        }
        break;

      case "boolean":
        break;

      default:
        if (key != CODED)
          addChar();
      }
      checkBackspace();
    }

    void checkBackspace() {
      if (key != BACKSPACE)return;

      if (userInput.length() > 0 && writeIndex > 0) {

        String begin = userInput.substring(0, writeIndex-1);
        String end = userInput.substring(writeIndex, userInput.length());

        userInput = begin + end;
        writeIndex -= 1;
      }
    }

    boolean charOnSide(char c, String side) {

      if (side.equals("left")) {
        for (int i = writeIndex-1; i >= 0; i--)
          if (userInput.charAt(i) == c)
            return true;
      } else if (side.equals("right")) {
        for (int i = writeIndex; i < userInput.length(); i++)
          if (userInput.charAt(i) == c)
            return true;
      }
      return false;
    }

    void addChar() {
      userInput = userInput.substring(0, writeIndex) + key + userInput.substring(writeIndex, userInput.length());
      if (userInput.length() == 0)
        userInput += key;
      writeIndex++;
    }

    // @Override
    void keyReleased() {
      if (!userIsTyping || ignore) return;
    }


    // @Override
    void keyPressed() {
      if (!userIsTyping || ignore) return;

      if (key == CODED) {

        switch(keyCode) {
        case RIGHT:
          writeIndex++;
          break;
        case LEFT:
          writeIndex--;
          break;
        }
      }
      writeIndex = constrain(writeIndex, 0, userInput.length());
    }

    <T> void insertElementAfterIndex(ArrayList<T> list, T object, int index) {

      list.add(object);
      for (int i = list.size()-1; i > index+1; i--) {
        list.set(i, list.get(i-1));

        //die y-Koordinate muss verändert werden
        if (list.get(i) instanceof TextField) {
          TextField field = (TextField) list.get(i);
          field.pos.y += size.y;
        }
      }
      list.set(index+1, object);
    }

    @Override
      void action() {

      if (ignore)
        return;

      if (TYPE.equals("boolean")) {
        value = !(boolean) value;
        userInput = str((boolean) value);
      }
      userIsTyping = true;
    }

    @Override
      void actionNotPressed() {

      if (ignore)
        return;

      helpString = "";
      userIsTyping = false;
    }

    void setValue() {

      //// irgendeinen Wert, damit es keine null-pointer Warnung gibt
      //Field field = main.getClass().getDeclaredFields()[0];
      //Class clazz = main.getClass();

      Field field = null;
      Object holdingObject = null;

      try {

        String object = getData(name, DATA_OBJECT);
        Field[] mainFields = MAIN.getClass().getDeclaredFields();

      search:
        for (int i = 0; i < mainFields.length; i++) {

          // Object finden
          if (!mainFields[i].getName().equals(object)) {
            continue;
          }

          holdingObject = mainFields[i].get(MAIN);

          Field[] objFields = holdingObject.getClass().getDeclaredFields();

          // variable finden
          for (int j = 0; j < objFields.length; j++) {
            if (!objFields[j].getName().equals(name))
              continue;

            field = objFields[j];
            break search;
          }
        }
      }
      catch(Exception f) {
        println("Error while setting values.");
        noLoop();
      }

      if (!TYPE.equals("boolean")) {
        value = (Object) userInput;
      }

      try {
        switch(TYPE) {
        case "boolean":
          field.setBoolean(holdingObject, (boolean) value);
          break;

        case "double":
          value = Double.parseDouble((value.toString()));
          field.setDouble(holdingObject, (double) value);
          break;

        case "float":
          value = float(value.toString());
          field.setFloat(holdingObject, (float) value);

          break;

        case "long":
          value = Long.parseLong((value.toString()));
          field.setLong(holdingObject, (long) value);
          break;

        case "int":
          value = int(value.toString());
          field.setInt(holdingObject, (int) value);
          break;

        case "byte":
          value = byte(int(value.toString()));
          field.setByte(holdingObject, (byte) value);
          break;
        }
      }
      catch (Exception e) {
        exitError(e, "error on field " + name);
      }
    }
  }
}
