const Jimp = require('jimp2');

//https://www.npmjs.com/package/jimp2

Jimp.read("./print/2310298.png", (err, larger) => {
  larger.resize(480, 1200);

  Jimp.read("./print/2310298.png", (err, orig) => {
    larger.composite(orig, 0, 0);

    Jimp.read("./print/2310298.png", (err, flip) => {
      flip.mirror(false, true);

      larger
        .composite(flip, 0, 600)
        .write(`./finalprint/${someId}.png`);
    });
  });
});