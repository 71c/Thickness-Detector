/*
Line Thickness Detector / Stroke-Thickness Visualizer
Created mainly from 2017-11-01 to 2017-11-06
Finds the thickness of lines and visualizes the the thickness
of the line at each every pixel on the line.
Inspired by Nina Stössinger’s stroke-thickness visualization
script that was made for Frere-Jones Type: http://ninastoessinger.com/about/news/visualizing-stroke-thickness-frerejones/
*/


import java.io.File;
PImage img;
String imgName;
PImage[] images;
float framesPerRotation; // Number of images it saves. Set lower for more speed or higher for more accuracy.
boolean savingDone;
HashMap<Point, Integer> minThicknesses; // the thickness at each point
ArrayList<Point> positions; // the points whose color is the foreground color

color foreground; // the original image's foreground color
color background; // the original image's background color
color lowThicknessColor; // The color in the gradient that represents low thickness
color highThicknessColor; // The color in the gradient that represents high thickness

String absolutePath;
String fileExtension;

void setup(){
  absolutePath = "/Users/alon/Documents/Processing/ThicknessDetector/data/"; // Replace this string by absolute path of the data folder (in the sketch folder). Command-K to show the sketch folder. If there is no folder in it called "data", make one. 
  fileExtension = "png";
  size(512,512);
  noSmooth();
  strokeWeight(2);
  imgName = "line.png";
  img = loadImage(imgName);
  
  framesPerRotation = 360; // Set this lower for more speed or higher for more accuracy and better looks
  
  //foreground = color(235, 235, 235);
  foreground = color(0);
  //background = color(30, 30, 30);
  background = color(255);
  
  //lowThicknessColor = color(254, 240, 50);
  lowThicknessColor = color(0);
  //highThicknessColor = color(217, 59, 66);
  highThicknessColor = color(255);
  
  images = new PImage[(int)framesPerRotation];
  minThicknesses = new HashMap<Point, Integer>();
  positions = new ArrayList<Point>();
  image(img, 0, 0);
  deleteFiles();
}

//Almost everything is in this draw loop: for certain sets of fraims a different function is done.
void draw(){
  if(frameCount <= framesPerRotation){ // saves all of the rotated images
    background(255);
    translate(width/2, height/2);
    rotate(radians((float)frameCount / framesPerRotation * 360f));
    image(img, -width/2, -height/2);
    saveFrame(absolutePath + "image-####." + fileExtension);
  }else if(frameCount <= 2 * framesPerRotation){ // adds all of the rotaed images to the images array
    println("image-" + java.lang.String.format("%04d", frameCount - (int)framesPerRotation) + "." + fileExtension);
    images[frameCount - (int)framesPerRotation - 1] = loadImage("image-" + java.lang.String.format("%04d", frameCount - (int)framesPerRotation) + "." + fileExtension);
  }else if(frameCount == 2 * framesPerRotation + 1){
    makePositionsAndMinThicknesses();
  }else if(frameCount <= 3 * framesPerRotation + 1){
    setThicknesses();
  } else if(frameCount == 3 * framesPerRotation + 2) {
    drawThicknesses();
  }
}

// adds the foreground positions to the positions ArrayList and the minThicknesses HashMap
void makePositionsAndMinThicknesses() {
  for(int y = 0; y < img.height; y++){
    for(int x = 0; x < img.width; x++){
      if(img.pixels[width*y+x] == foreground){
        positions.add(new Point(x, y));
        minThicknesses.put(new Point(x, y), 0);
      }
    }
  }
}

// sets the (minimum) thicknesses in the minThicknesses HashMap
void setThicknesses() {
  int degrees = (frameCount - 2) % (int)framesPerRotation;
  PImage currentImage = images[degrees];
  image(currentImage, 0, 0);
  for(Point p : minThicknesses.keySet()) {
    float r = dist(img.width/2, img.height/2, p.x, p.y);
    float d = degrees(atan2(p.x - img.width/2, p.y - img.height/2)) - ((degrees + 1) * 360 / framesPerRotation);
    int newX = int(r * sin(radians(d))) + img.width/2;
    int newY = int(r * cos(radians(d))) + img.height/2;
    if(currentImage.get(newX, newY) == foreground) {
      int h = findHorizontalThickness(currentImage, new Point(newX, newY));
      if(h < minThicknesses.get(p).intValue() || minThicknesses.get(p).intValue() == 0)
        minThicknesses.put(p, h);
    }
  }
}

// draws the thicknesses from the minThicknesses HashMap
void drawThicknesses() {
  int max = 0;
  int min = Integer.MAX_VALUE;
  for(Point p : minThicknesses.keySet()) {
    if(minThicknesses.get(p).intValue() > max)
      max = minThicknesses.get(p).intValue();
    if(minThicknesses.get(p).intValue() < min)
      min = minThicknesses.get(p).intValue();
  }
  System.out.println(min);
  System.out.println(max);
  background(0);
  for(Point p : minThicknesses.keySet()) {
    //stroke(map(minThicknesses.get(p).intValue(), min, max, 0, 255));
    stroke(lerpColor(lowThicknessColor, highThicknessColor, map(minThicknesses.get(p).intValue(), min + 15, max - 15, 0, 1)));
    point(p.x, p.y);
  }
  //save("done" + (int)random(999) + ".png");
  save("thickness " + imgName + " " + framesPerRotation + "fpr " + hex(lowThicknessColor) + " to " + hex(highThicknessColor) + ".png");
}

//Extend a horizontal line to the left and the right of a point that is on the line to measure the thickness of. The ends of this horizontal line are at the ends of the big line.
int findHorizontalThickness(PImage image, Point p) {
  //System.out.println("(" + p.x + ", " + p.y + ")");
  assert image.pixels[image.width*p.y+p.x] == foreground;
  int leftX = p.x;
  while (leftX >= 0 && image.pixels[image.width*p.y + leftX] == foreground) {
    leftX--;
  }
  int rightX = p.x;
  while (rightX < image.width && image.pixels[image.width * p.y  + rightX] == foreground) {
    rightX++;
  }
  return rightX - leftX - 1;
}

void deleteFiles(){
  int i = 1;
  File f = new File(dataPath(absolutePath + "image-" + java.lang.String.format("%04d", i) + "." + fileExtension));
  while(f.exists()){
    if(f.exists()) f.delete();
    i++;
    f = new File(dataPath(absolutePath + "image-" + java.lang.String.format("%04d", i) + "." + fileExtension));
  }
}
