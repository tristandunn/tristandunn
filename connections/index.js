/* global document,Image,URL */

import Tesseract from "https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.esm.min.js";

class Helper {
  static colors = [
    "rgb(244, 224, 127)",
    "rgb(166, 194, 103)",
    "rgb(181, 195, 235)",
    "rgb(178, 131, 193)"
  ];

  constructor() {
    this.scheduler = Tesseract.createScheduler();

    this.bindImageInput();
  }

  bindDeselectAll() {
    document.querySelector("#deselect-all").addEventListener("click", (event) => {
      event.preventDefault();

      this.tiles.forEach((element) => {
        element.style.backgroundColor = "";
      });
    });
  }

  bindImageInput() {
    const input = document.querySelector("#upload input");

    input.addEventListener("change", this.onImageChange.bind(this));
  }

  bindShuffle() {
    document.querySelector("#shuffle").addEventListener("click", (event) => {
      event.preventDefault();

      const board = document.querySelector("#board"),
            elements = board.children,
            fragment = document.createDocumentFragment();

      while (elements.length) {
        fragment.appendChild(elements[Math.floor(Math.random() * elements.length)]);
      }

      board.appendChild(fragment);
    });
  }

  createBoard(words) {
    const board = document.querySelector("#board"),
          helper = document.querySelector("#helper");

    this.tiles = words.map((word) => {
      const element = document.createElement("div");

      element.dataset.word = word.trim();
      element.addEventListener("click", this.onWordClick.bind(this));

      board.appendChild(element);

      return element;
    });

    helper.style.display = "";
  }

  createRectangles(image) {
    const size = Math.round(image.width * 0.90 / 4.0),
          rectangles = [];

    for (let x = 0; x < 4; x++) {
      for (let y = 0; y < 4; y++) {
        rectangles.push({
          "top": Math.round(image.height * 0.186695279) + size * y + Math.round(image.width * 0.01860465116) * y,
          "left": Math.round(image.width * 0.02248062016) + size * x + Math.round(image.width * 0.01860465116) * x,
          "width": size,
          "height": size
        });
      }
    }

    return rectangles;
  }

  async findWords(rectangles) {
    const results = await Promise.all(rectangles.map((rectangle) => {
      return this.scheduler.addJob("recognize", this.file, { rectangle });
    }));

    await this.scheduler.terminate();

    return results.map((result) => {
      return result.data.text;
    });
  }

  loadImage() {
    const image = new Image();

    image.addEventListener("load", this.onImageLoad.bind(this));
    image.src = URL.createObjectURL(this.file);
  }

  onImageChange(event) {
    const file = event.target.files[0];

    if (!file) {
      return;
    }

    event.target.parentNode.remove();

    this.file = file;
    this.loadImage();
  }

  async onImageLoad(event) {
    const image = event.target,
          rectangles = this.createRectangles(image),
          workers = [
            await Tesseract.createWorker("eng"),
            await Tesseract.createWorker("eng")
          ];

    workers.forEach((worker) => {
      this.scheduler.addWorker(worker);
    });

    const words = await this.findWords(rectangles);

    this.createBoard(words);
    this.bindDeselectAll();
    this.bindShuffle();
  }

  onWordClick(event) {
    const element = event.target;

    element.style.backgroundColor = Helper.colors[
      Helper.colors.indexOf(element.style.backgroundColor) + 1
    ] || "";

    event.preventDefault();
  }
}

new Helper();
