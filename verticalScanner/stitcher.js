const Jimp = require('jimp2');

//https://www.npmjs.com/package/jimp2

new Promise(resolve => {
  Jimp.read(`./print/test.jpg`, (err, larger) => {
    larger.resize(480, 1200);

    Jimp.read(`./print/test.jpg`, (err, orig) => {
      larger.composite(orig, 0, 0);

      Jimp.read(`./print/test.jpg`, (err, flip) => {
        flip.mirror(false, true);

        larger
          .composite(flip, 0, 600)
          .write(`./finalprint/final.png`, () => {
            resolve();
            console.log('test');
          });
      });
    });
  });
});