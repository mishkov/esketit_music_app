self.onmessage = (event) => {
  const data = event.data || {};
  const id = data.id;
  const pixels = data.pixels;

  if (typeof id !== 'number' || !pixels) {
    return;
  }

  try {
    let redTotal = 0;
    let greenTotal = 0;
    let blueTotal = 0;
    let alphaTotal = 0;

    for (let offset = 0; offset < pixels.length; offset += 4) {
      const alpha = pixels[offset + 3];
      if (alpha === 0) {
        continue;
      }

      redTotal += pixels[offset] * alpha;
      greenTotal += pixels[offset + 1] * alpha;
      blueTotal += pixels[offset + 2] * alpha;
      alphaTotal += alpha;
    }

    if (alphaTotal === 0) {
      self.postMessage({ id, rgbValue: null });
      return;
    }

    const red = Math.floor(redTotal / alphaTotal);
    const green = Math.floor(greenTotal / alphaTotal);
    const blue = Math.floor(blueTotal / alphaTotal);
    const rgbValue = (red << 16) | (green << 8) | blue;

    self.postMessage({ id, rgbValue });
  } catch (error) {
    self.postMessage({
      id,
      error: error instanceof Error ? error.message : String(error),
    });
  }
};
