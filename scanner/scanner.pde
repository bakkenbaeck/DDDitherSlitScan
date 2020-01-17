import processing.video.*;

Capture cam;
final int MAX_LEVEL = 5;
int level = 4;
int videoSliceX;
int drawPositionX;
PImage frameGraphic;
PGraphics ditheredImage;
PGraphics ui;
PGraphics frame;
PGraphics cameraOverlay;
String scanStatus;
boolean initialized;

void setup() {
  size(640, 480);

  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");

    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    scanStatus = "idle";
    cam = new Capture(this, cameras[0]);
    cam.start(); 

    ui = createGraphics(width, height);
    frame = createGraphics(width, height);
    ditheredImage = createGraphics(width, height);
    cameraOverlay = createGraphics(width, height);
    
    frameGraphic = loadImage("frame.png");

    videoSliceX = cam.width / 2;
    drawPositionX = width - 1;
    
    background(255);
  }      
}

void draw() {
  if (cam.available()) {
    cam.read();
    cam.loadPixels();
    
    if (scanStatus == "scanning") {
      ditheredImage.beginDraw();
        ditheredImage.loadPixels();
        
        for (int y = 0; y < cam.height; y++) {
          int setPixelIndex = y * width + drawPositionX;
          int getPixelIndex = y * cam.width  + videoSliceX; // you can play with changing sliceX with drawPositionX
          ditheredImage.pixels[setPixelIndex] = cam.pixels[getPixelIndex];
        }
  
        dither();
        ditheredImage.updatePixels();
      ditheredImage.endDraw();
      
      image(ditheredImage.get(0, 0, width - 20, height - 50), 10, 40);
      
      drawPositionX--;
      
      // HELP! i cannot for the life of me get ui (PGRaphic) to CLEAR!!!! it needs to clear!
      ui.beginDraw();
        ui.clear();
        // get the selected area from PImage of cam, then draw it -10 pixels to the left of the output line
        int y = 40;
        int sourceX = (cam.width / 2) - 10;
        int sourceWidth = 20;
        int sourceHeight = cam.height - y;
        int w = 20;
        int h = height - 50;
        image(cam.get(sourceX, 0, sourceWidth, sourceHeight), drawPositionX, y, w, h);
      ui.endDraw();
  
      frame.beginDraw();
        image(frameGraphic, 0, 0);
      frame.endDraw();
      
      if (drawPositionX == 0) {
        ui.clear(); // BUG: this needs to CLEAR!
        scanStatus = "idle";
        save("print/" + day() + hour() + minute() + second() + ".jpg");
      }
    }
    
    if (scanStatus == "idle") {
      // display the final image ONLY if it has already been rendered once
      // this shows the user the final image for printing
      if (initialized) {
        image(ditheredImage.get(0, 0, width - 20, height - 50), 10, 40);
      }
        
      ui.beginDraw();
        textSize(18);
        textAlign(CENTER);
        fill(255, 0, 0);
        text("Click anywhere to scan!", width / 2, height / 2);
      ui.endDraw();
    }
  }
}

void mousePressed() {
  if (scanStatus == "idle") {
    drawPositionX = width - 1;
    scanStatus = "scanning";
  }
}

// This is just a run off the mill algo from the web of a dither method
void dither() {
  float f = 255.0/ (pow(2, 2 * level) + 1);

  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      int pos = x + y * width;

      color c = ditheredImage.pixels[pos];

      if (level < MAX_LEVEL) {
        // Compute the threshold to apply, depending on user input
        float threshold = level > 0 ? dizza(x, y, level) * f : 128;
        // Decompose the color in its components
        int red = (c >> 16) & 0xFF;
        int green = (c >> 8) & 0xFF;
        int blue = c & 0xFF;

        if (key == 'c') {
          // Above threshold, black, otherwise, white
          int r = threshold >= red ? 0 : 255;
          int g = threshold >= green ? 0 : 255;
          int b = threshold >= blue ? 0 : 255;
          // Recombine the color channels
          c = (r << 16) | (g << 8) | b;
        }
        
        // Black & White, compare threshold to the average of the three channels
        if (threshold >= (red + green + blue) / 3.0) {
          c = color(0); // Black
        } else {
          c = color(255); // White
        }
      }

      ditheredImage.pixels[pos] = c;
    }
  }
}

int dizza(int i, int j, int n) {
  if (n == 1) {
    return (i % 2 != j % 2 ? 2 : 0) + j % 2;
  } else {
    // Recursive call
    return 4 * dizza(i % 2, j % 2, n-1) + dizza(int(i/2), int(j/2), n-1);
  }
}
