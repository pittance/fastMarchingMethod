
class Isorender {
  
  //data array
  float[][] field;    //main data storage
  
  //we're going to draw into this
  PGraphics p;
  
  float step = 0.09;
  float levels = 100;
  int cols, rows;
  int rez;            //resolution => makes the plot bigger
  
  float rngLo = -1;
  float rngHi = 1;
  
  
  Isorender(float[][] field, int rez) {
    this.rez = rez;
    setData(field);
    p = createGraphics(640,480);
  }
  
  //setting the data for the calculation and rendering
  void setData(float[][] field) {
    this.field = field;
    cols = field.length;
    rows = field[0].length;
  }
  
  void draw() {
    //draws into the PGraphics offline buffer
    
    //find the max/min of the field range
    float maxField = field[0][0];
    float minField = field[0][0];
    for (int i = 0; i < cols; i++) {
        for (int j = 0; j < rows; j++) {
          if(field[i][j] > maxField){
            maxField = field[i][j];
            //println(maxField);
          }
          if(field[i][j] < minField){
            minField = field[i][j];
            //println(minField);
          }
        }
    }
    rngLo = minField;
    rngHi = maxField;
    
    //loop over the range
    p.beginDraw();
    p.background(255);
    for (float h = rngLo; h < rngHi; h += step) {
      p.stroke(0);
      p.strokeWeight(0.75);
      //loop over the data
      for (int i = 0; i < cols - 1; i++) {
        for (int j = 0; j < rows - 1; j++) {
          float f0 = field[i][j] - h;
          float f1 = field[i + 1][j] - h;
          float f2 = field[i + 1][j + 1] - h;
          float f3 = field[i][j + 1] - h;
    
          float x = i * rez;
          float y = j * rez;
          PVector a = new PVector(x + rez * f0 / (f0 - f1), y);
          PVector b = new PVector(x + rez, y + rez * f1 / (f1 - f2));
          PVector c = new PVector(x + rez * (1 - f2 / (f2 - f3)), y + rez);
          PVector d = new PVector(x, y + rez * (1 - f3 / (f3 - f0)));
    
          int state = getState(f0, f1, f2, f3);
          switch (state) {
            case 1:
              drawLine(c, d);
              break;
            case 2:
              drawLine(b, c);
              break;
            case 3:
              drawLine(b, d);
              break;
            case 4:
              drawLine(a, b);
              break;
            case 5:
              drawLine(a, d);
              drawLine(b, c);
              break;
            case 6:
              drawLine(a, c);
              break;
            case 7:
              drawLine(a, d);
              break;
            case 8:
              drawLine(a, d);
              break;
            case 9:
              drawLine(a, c);
              break;
            case 10:
              drawLine(a, b);
              drawLine(c, d);
              break;
            case 11:
              drawLine(a, b);
              break;
            case 12:
              drawLine(b, d);
              break;
            case 13:
              drawLine(b, c);
              break;
            case 14:
              drawLine(c, d);
              break;
          }
        }
      }
    }
    p.endDraw();
  }
  
  void drawScreen(float levels) {
    //draws into the screen
    this.levels = levels;
    
    
    //find the max/min of the field range
    float maxField = field[0][0];
    float minField = field[0][0];

    for (int i = 0; i < cols; i++) {
        for (int j = 0; j < rows; j++) {
          if(field[i][j] > maxField){
            maxField = field[i][j];
          }
          if(field[i][j] < minField){
            minField = field[i][j];
          }
        }
    }
    rngLo = minField;
    rngHi = maxField;
    
    println("drawing to screen with max: " + rngHi + ", and min: " + rngLo);
    
    step = (rngHi-rngLo)/levels;
    
    //loop over the range
    background(255);
    stroke(0,220);
    strokeWeight(0.75);
    noFill();
    for (float h = rngLo; h < rngHi; h += step) {
      //loop over the data
      for (int i = 0; i < cols - 1; i++) {
        for (int j = 0; j < rows - 1; j++) {
          float f0 = field[i][j] - h;
          float f1 = field[i + 1][j] - h;
          float f2 = field[i + 1][j + 1] - h;
          float f3 = field[i][j + 1] - h;
    
          float x = i * rez;
          float y = j * rez;
          PVector a = new PVector(x + rez * f0 / (f0 - f1), y);
          PVector b = new PVector(x + rez, y + rez * f1 / (f1 - f2));
          PVector c = new PVector(x + rez * (1 - f2 / (f2 - f3)), y + rez);
          PVector d = new PVector(x, y + rez * (1 - f3 / (f3 - f0)));
    
          int state = getState(f0, f1, f2, f3);
          switch (state) {
            case 1:
              drawLineScreen(c, d);
              break;
            case 2:
              drawLineScreen(b, c);
              break;
            case 3:
              drawLineScreen(b, d);
              break;
            case 4:
              drawLineScreen(a, b);
              break;
            case 5:
              drawLineScreen(a, d);
              drawLineScreen(b, c);
              break;
            case 6:
              drawLineScreen(a, c);
              break;
            case 7:
              drawLineScreen(a, d);
              break;
            case 8:
              drawLineScreen(a, d);
              break;
            case 9:
              drawLineScreen(a, c);
              break;
            case 10:
              drawLineScreen(a, b);
              drawLineScreen(c, d);
              break;
            case 11:
              drawLineScreen(a, b);
              break;
            case 12:
              drawLineScreen(b, d);
              break;
            case 13:
              drawLineScreen(b, c);
              break;
            case 14:
              drawLineScreen(c, d);
              break;
          }
        }
      }
    }
  }
  
  //used in draw()
  private void drawLine(PVector v1, PVector v2) {
    p.line(v1.x, v1.y, v2.x, v2.y);
  }
  
  private void drawLineScreen(PVector v1, PVector v2) {
    line(v1.x, v1.y, v2.x, v2.y);
  }
  
  int getState(float a, float b, float c, float d) {
    return (a > 0 ? 8 : 0) + (b > 0 ? 4 : 0) + (c > 0 ? 2 : 0) + (d > 0 ? 1 : 0);
  }
  
  
}
