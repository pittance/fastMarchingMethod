import processing.svg.*;

//fast marching method class
FMM fmm;

//size of the array to calculate - set from image
int numZ = 0;
int numX = 0;

//starting point for the calculation
int startZ = 155;
int startX = 90;

//no idea what these do, they're used in the calculation but don't seem to change the output patterns
int sampZ = 1;  
int sampX = 1;

//output array
float[][] tout;

//class to show contours of the time
Isorender iso;

//input image
PImage source;

//class to process the image to get brightness
Imgproc imgproc;

boolean export = false;


void setup() {
  size(1280,960);
  smooth();
  
  //load the image & process it - use it for the speed array
  source = loadImage("Human eye, anteriorview.jpg");
  //image source is:
  //  https://commons.wikimedia.org/wiki/File:Human_eye,_anterior_view.jpg
  //  licensed under the Creative Commons Attribution-Share Alike 4.0 International license.
  //  Author: Rapidreflex
  
  imgproc = new Imgproc();
  float[][] slow = imgproc.getBright(source,true);
  numX = imgproc.high;
  numZ = imgproc.wide;
  
  //instantiate the calculation class
  fmm = new FMM(startZ, startX, numZ, numX, sampZ, sampX, slow);
  println("numZ,numX,numX*numZ",numZ,numX,numX*numZ);
  
  //run solver & return the array
  println("running solver...");
  tout = fmm.solver();  //run the solution
  println("...done solver");
  
  //set up the isoline contour output
  //  ==> we input the data to plot in tout
  //  ==> the next parameter is a scaling factor (integer)
  iso = new Isorender(tout,3);
  
}



void draw() {
  background(200);
  
  println("starting draw...");
  
  if(export) {
    println("starting export...");
    beginRecord(SVG,"export.svg");
  }
  
  //the parameter is the number of isolines to use
  iso.drawScreen(200);
  
  println("...done draw");
  
  if(export) {
    println("...ending record...");
    endRecord();
    println("...done export");
    exit();
  }
}

void keyPressed() {
  if((key=='e')||(key=='s')) export = true;
}
