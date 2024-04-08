static abstract class Window extends PApplet {

  boolean freezed = false;

  // Anordnung der Fenster
  static final float OFFSET_X = 0.5;
  static final float OFFSET_Y = 0.37;

@Override
  void settings() {
  size(int(displayWidth/2.03), int(displayHeight/3)); // ,P2D
}

  void setLocation(int x, int y) {
    surface.setLocation(int(displayWidth/2-width/2+(OFFSET_X*displayWidth/2 *x)), int(displayHeight/2-height/2+(OFFSET_Y*displayHeight/2 *y)));
  }

  @Override
    abstract void setup();
  @Override
    abstract void draw();

  @Override
    void exit() {
    freeze();
  }

  void freeze() {
    this.surface.setVisible(false);
    freezed = true;
  }

  void deFreeze() {

    if (surface == null) {
      PApplet.runSketch(new String[]{getClass().getSimpleName()}, this);
      return;
    }
    this.surface.setVisible(true);
    freezed = false;
  }
}
