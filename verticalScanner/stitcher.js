const Jimp = require('jimp2');

//https://www.npmjs.com/package/jimp2

Promise.all([
  Jimp.read(`./print/${sourceFile}.png`),
  Jimp.read(`./print/${sourceFile}.png`),
  Jimp.read(`./print/${sourceFile}.png`),
])
  .then(([ larger, orig, flip ]) => {
    larger.resize(480, 1200);
    larger.composite(orig, 0, 0);
    flip.mirror(false, true);

    larger
      .composite(flip, 0, 600)
      .grayscale(100)
      .write(`./finalprint/${someId}.png`);
  });