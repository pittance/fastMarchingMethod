
class Imgproc {
  int wide;
  int high;
  
  Imgproc() {
  }
  
  float[][] getBright(PImage in, boolean invert) {
    this.wide = in.width;
    this.high = in.height;
    
    float[][] bright = new float[wide][high];
    
    for(int i=0;i<wide;i++) {
      for(int j=0;j<high;j++) {
        bright[i][j] = brightness(in.get(i,j));
        if(invert) bright[i][j] = map(bright[i][j],0,255,255,0);
      } 
    }
    return bright;
  }
  
  
}
