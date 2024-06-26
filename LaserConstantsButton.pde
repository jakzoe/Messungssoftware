@FunctionalInterface
  interface LaserConstantsButtonAction {
  void f(LaserConstantsButton self);
}

class LaserConstantsButton {

  PVector pos, size;
  LaserConstantsButtonAction show, action;
  color c = color(255, 0, 0);
  boolean ignore = false;
  long time = -1;
  boolean active = true;

  LaserConstantsButton(float x, float y, float sx, float sy) {
    this(x, y, sx, sy, null);
  }

  LaserConstantsButton(float x, float y, float sx, float sy, LaserConstantsButtonAction a, LaserConstantsButtonAction _show) {
    this(x, y, sx, sy, a);
    show = _show;
    show = (self) -> {
      _show.f(this);
      time = millis();
    };
  }

  LaserConstantsButton(float x, float y, float sx, float sy, LaserConstantsButtonAction a) {

    pos = new PVector(x, y);
    size = new PVector(sx, sy);
    action = a;
  }

  // @Override
  void mouseReleased(int mouseX, int mouseY) {

    // wenn die Funktion show.f() des buttons 500ms nicht aufgerufen wurde
    if (time+500 < millis() && time != -1)
      active = false;
    else
      active = true;

    if (!active)
      return;

    if (onButton(mouseX, mouseY)) {

      if (action != null)
        action.f(this);
      else
        action();
    } else if (action == null) {
      actionNotPressed();
    }
  }

  boolean onButton(int mouseX, int mouseY) {
    return !ignore && (pos.x-size.x/2 < mouseX && pos.x+size.x/2 > mouseX && pos.y-size.y/2 < mouseY && pos.y+size.y/2 > mouseY);
  }

  // für erbende Klassen zum überschreiben
  void action() {
    this.action.f(this);
  }

  void show() {
    this.show.f(this);
  }

  void actionNotPressed() {
  }
}
