// Adapted version of
//Tyler Paige's Vertical scanner, September 2012
//Based off Golan Levin's "Simple Real-Time Slit-Scan Program"
// DDD modifications to expand and dither the resulting camera image
import processing.video.*; //This slitscan uses live video from your webcam
Capture camera;

int videoWidth = 480;
int videoHeight = 640;
int currentY = 0;
String status = "idle";
PGraphics output;
PGraphics ditheredImage;
PGraphics ui;
PGraphics window;
boolean isNewFrame  = false;  // fresh-frame flag

void setup(){
  size(480, 640);
  background(255);

  output = createGraphics(width, 480);
  ui = createGraphics(width, height);
  ditheredImage = createGraphics(width, 480);
  window = createGraphics(width, 480);

  String[] cameras = Capture.list();
  camera = new Capture(this, cameras[0]); //Get the live camera feed
  camera.start();
}

public void captureEvent(Capture c) {
  c.read();
  isNewFrame = true;
}

void draw() {
  if (isNewFrame && status == "scanning") {
    camera.filter(GRAY);
    
    output.beginDraw();
      output.copy(
        camera, // source
        0, // sx
        currentY, // sy
        camera.width, // sw
        currentY, // sh
        0, // dx
        currentY, // dy
        width, // dw
        currentY // dh
       );
       //output.updatePixels();
    output.endDraw();
    
    ditheredImage.beginDraw();
      image(output.get(0, 0, width, currentY), 0, 0, width, 480);
      
      ditheredImage.loadPixels();
      for (int y = 0; y < floor(width * ((currentY + 2) * 1.3)) && y < ditheredImage.pixels.length; y++) {
        ditheredImage.pixels[y] = output.pixels[y];
      }
      newDither();
      ditheredImage.updatePixels();
    ditheredImage.endDraw();
    
    //window.beginDraw();
    //  image(camera, 0, 0, width, height);
    //  window.updatePixels();
    //window.endDraw();
    
    image(ditheredImage, 0, 0, width, height);
    //image(window, 0, 0, width, height);
    
    ui.beginDraw();
      stroke(255, 0, 0);
      strokeWeight(4);
      line(0, (currentY + 2) * 1.3, width, (currentY + 2) * 1.3);
    ui.endDraw();

    if (currentY == height) {
      status = "idle";
      save("print/" + day() + hour() + minute() + second() + ".png");
    } else {
      currentY++;
    }
    
    //currentY %= height;
  }
}

void mousePressed() {
  if (status == "idle") {
    currentY = 0;
    status = "scanning";
  }
}

int index(int x, int y) {
  return x + y * ditheredImage.width;
}

void newDither() {
  for (int y = 0; y < ditheredImage.height-1; y++) {
    for (int x = 1; x < ditheredImage.width-1; x++) {
      color pix = ditheredImage.pixels[index(x, y)];
      float oldR = red(pix);
      float oldG = green(pix);
      float oldB = blue(pix);
      int factor = 1;
      int newR = round(factor * oldR / 255) * (255/factor);
      int newG = round(factor * oldG / 255) * (255/factor);
      int newB = round(factor * oldB / 255) * (255/factor);
      ditheredImage.pixels[index(x, y)] = color(newR, newG, newB);

      float errR = oldR - newR;
      float errG = oldG - newG;
      float errB = oldB - newB;


      int index = index(x+1, y  );
      color c = ditheredImage.pixels[index];
      float r = red(c);
      float g = green(c);
      float b = blue(c);
      r = r + errR * 7/16.0;
      g = g + errG * 7/16.0;
      b = b + errB * 7/16.0;
      ditheredImage.pixels[index] = color(r, g, b);

      index = index(x-1, y+1  );
      c = ditheredImage.pixels[index];
      r = red(c);
      g = green(c);
      b = blue(c);
      r = r + errR * 3/16.0;
      g = g + errG * 3/16.0;
      b = b + errB * 3/16.0;
      ditheredImage.pixels[index] = color(r, g, b);

      index = index(x, y+1);
      c = ditheredImage.pixels[index];
      r = red(c);
      g = green(c);
      b = blue(c);
      r = r + errR * 5/16.0;
      g = g + errG * 5/16.0;
      b = b + errB * 5/16.0;
      ditheredImage.pixels[index] = color(r, g, b);


      index = index(x+1, y+1);
      c = ditheredImage.pixels[index];
      r = red(c);
      g = green(c);
      b = blue(c);
      r = r + errR * 1/16.0;
      g = g + errG * 1/16.0;
      b = b + errB * 1/16.0;
      ditheredImage.pixels[index] = color(r, g, b);
    }
  }
}
