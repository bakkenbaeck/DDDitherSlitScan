"use strict";

import dotenv from "dotenv";
import chalk from "chalk";
import chokidar from "chokidar";
import { printer as ThermalPrinter, types } from "node-thermal-printer";
import sanityClient from '@sanity/client'
import fs from 'fs';
import path from 'path';
import Jimp from 'jimp2';
import moment from 'moment';

// Configure Dotenv to read environment variables from .env file
// automatically
dotenv.config();

const headerQuotes = [
  {
    person: "Jorge Luis Borges",
    quote: "“We are our memory, we are that chimerical museum of shifting shapes, that pile of broken mirrors.”",
  },
  {
    person: "Paul Klee",
    quote: "“Everything vanishes around me, and works are born as if out of the void. Ripe, graphic fruits fall off.”",
  },
  {
    person: "Oscar Wilde",
    quote: "“Memory, like a horrible malady, was eating his soul away.”",
  },
  {
    person: "Virginia Woolf",
    quote: "“Memory runs her needle in and out, up and down, hither and thither. We know not what comes next, or what follows after.”",
  },
  {
    person: "Sylvia Plath",
    quote: "“Remember, remember, this is now, and now, and now. Live it, feel it, cling to it.”",
  },
  {
    person: "Walter Benjamin",
    quote: "“Memory is not an instrument for surveying the past — its theater.”",
  },
  {
    person: "Charles Baudelaire",
    quote: "“Remembering is only a new way of suffering.”",
  },
];

const footerQuotes = [
  "We couldn't find the image you're looking for",
  "[There doesn't appear to be anyone here]",
  "Image Not Found",
  "Oops, looks like you are lost",
  "Something's wrong, try again",
  "There's been a glitch in the system",
  "Oh uh, your face is no longer there",
  "Your requested image was not found",
  "This image is broken",
  "There is no one here",
  "User identity is fragmented",
];

function getSample(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

async function printImage(printer, image, counter) {

  console.log(chalk.green('Start printing image...'));

  const headerQuote = getSample(headerQuotes);
  const footerQuote = getSample(footerQuotes);

  const date = moment().format('DD.MM.YYYY, HH:mm');

  try {
    printer.clear();

    printer.alignCenter();
    printer.println("Bakken & Bæck");
    printer.println("Van Diemenstraat 38");
    printer.println("1013 NH Amsterdam");

    printer.alignRight();

    printer.newLine();

    printer.println(date);
    printer.println(`#${counter}`);

    printer.newLine();

    printer.alignCenter();
    printer.println("* * * * * * * * * *");

    printer.invert(false);

    // printer.setTypeFontB();
    // printer.setTextSize(1,1);

    printer.newLine();

    printer.alignLeft();
    printer.println(headerQuote.quote);

    printer.newLine();

    printer.alignRight();
    printer.println(`— ${headerQuote.person}`);

    printer.newLine();

    printer.alignCenter();

    printer.newLine();

    await printer.printImage(image);

    printer.newLine();
    printer.newLine();

    printer.println("404");
    printer.println(footerQuote);

    printer.newLine();

    await printer.printImage("./ddd.png");

    printer.cut();
    // printer.clear();
    printer.execute();

    console.log(chalk.green('Image printed'));
  } catch(error) {
    console.log(chalk.red('Error printing image', error));
  }
}

function transformImage(sourceFile) {
  const transformedPath = sourceFile.replace('print', 'finalprint');

  return new Promise(resolve => {
    Jimp.read(sourceFile, (err, larger) => {
      larger.resize(480, 1200);
      Jimp.read(sourceFile, (err, orig) => {
        larger.composite(orig, 0, 0);
        Jimp.read(sourceFile, (err, flip) => {
          flip.mirror(false, true);
          larger
            .composite(flip, 0, 600)
            .dither565()
            .write(transformedPath, () => {
              resolve(transformedPath);
            });
        });
      });
    });
  });
}

function sendToServer(client, filePath) {
  client.assets.upload('image', fs.createReadStream(filePath), {
    filename: path.basename(filePath)
  }).then(_imageAsset => {
    console.log(chalk.green('Asset uploaded to Sanity'));
  });
}

async function setupPrinter() {
  const printer = new ThermalPrinter({
    type: types.EPSON,
    interface: "tcp://192.168.1.205:9100"
  });

  let isConnected = await printer.isPrinterConnected();

  if (isConnected) {
    console.log(chalk.green('Printer connected.'));
  } else {
    console.log(chalk.red('Printer not connected. Try again.'));
  }

  return printer;
}

function setupSanity() {
  return sanityClient({
    projectId: process.env.SANITY_PROJECT_ID,
    dataset: process.env.SANITY_DATASET,
    token: process.env.SANITY_TOKEN
  });
}

async function setup() {
  // const client = setupSanity();
  const printer = await setupPrinter();

  let counter = 10001;

  // Initialize watcher.
  const watcher = chokidar.watch(process.env.FOLDER, {
    ignored: /(^|[\/\\])\../, // ignore dotfiles
    persistent: true,
    ignoreInitial: true,
  });

  watcher.on('add', async (path) => {
    console.log(chalk.green(`file added at path: ${path}`));

    setTimeout(async () => {
      // const newPath = await transformImage(path);
      await printImage(printer, path, counter);

      counter++;

    }, 2000);


    // sendToServer(client, path);
  });
}

setup();