/*
The MIT License (MIT)

huepi is Copyright (c) 2013 Arnd Brugman

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import 'dart:math' as math;

class HueColor {
  //range is 0..65535
  num hue = 0;

  //range is 0..255
  num saturation = 0;

  //range is 0..255
  num brightness = 0;

  //range is 2200..6500
  num temperature = 0;

  //Ct = 10^6 / color temperature, range is 153 (6500K) to 500 (2000K)
  num ct = 0;

  //range is [0..1, 0..1]
  List<num> xy = [];

  //range is 0..1
  num red = 0;

  //range is 0..1
  num green = 0;

  //range is 0..1
  num blue = 0;

  HueColor({this.hue, this.saturation, this.brightness, this.ct, this.temperature, this.xy, this.red, this.green, this.blue});

  @override
  String toString() => 'rgb: ($red, $green, $blue). hsb: ($hue, $saturation, $brightness). ct: $ct, temperature: $temperature. xy: $xy';
}

class ColorHelper {
  /// Converts rgb values to hue, saturation and brightness.
  ///
  /// returns an [HueColor] with the [red], [green], [blue] values ranging from 0 to 1 converted to
  /// hue, saturation and brightness.
  HueColor rgbToHueSaturationBrightness(num red, num green, num blue) {
    num hue, saturation, brightness;
    var min = [red, green, blue].reduce(math.min);
    var max = [red, green, blue].reduce(math.max);
    if (min != max) {
      if (red == max) {
        hue = (0 + ((green - blue) / (max - min))) * 60;
      } else if (green == max) {
        hue = (2 + ((blue - red) / (max - min))) * 60;
      } else {
        hue = (4 + ((red - green) / (max - min))) * 60;
      }
      saturation = (max - min) / max;
      brightness = max;
    } else {
      // Max == Min
      hue = 0;
      saturation = 0;
      brightness = max;
    }

    while (hue < 0) {
      hue = hue + 360;
    }
    hue = hue % 360;
    return new HueColor(
        hue: (hue / 360 * 65535).round(),
        saturation: (saturation * 255).round(),
        brightness: (brightness * 255).round(),
        red: red,
        green: green,
        blue: blue);
  }

  /// Converts [hue], [saturation] and [brightness] to rgb values
  HueColor hueSaturationBrightnessToRGB(num hue, num saturation, num brightness) {
    var _hue = hue * 360 / 65535;
    var _saturation = saturation / 255;
    var _brightness = brightness / 255;
    final rgbColor = _hsbToRGB(_hue, _saturation, _brightness);
    final temperatureColor = _rgbToColorTemperature(rgbColor.red, rgbColor.green, rgbColor.blue);
    final ctColor = _colorTemperatureToCT(temperatureColor.temperature);
    final xyColor = rgbToXY(rgbColor.red, rgbColor.green, rgbColor.blue);
    rgbColor.hue = hue;
    rgbColor.saturation = saturation;
    rgbColor.brightness = brightness;
    rgbColor.ct = ctColor.ct;
    rgbColor.temperature = temperatureColor.temperature;
    rgbColor.xy = xyColor.xy;
    return rgbColor;
  }

  /// Converts hue, saturation and brightness to rgb.
  ///
  /// returns an [HueColor] with the [hue] ranging from 0 to 360, [saturation] and [brightness] both ranging from 0 to 1 converted to
  /// red, green and blue.
  HueColor _hsbToRGB(num hue, num saturation, num brightness) {
    var red, green, blue;
    if (saturation == 0) {
      red = brightness;
      green = brightness;
      blue = brightness;
    } else {
      var sector = (hue / 60).floor() % 6;
      var fraction = hue / 60 - sector;
      var p = brightness * (1 - saturation);
      var q = brightness * (1 - saturation * fraction);
      var t = brightness * (1 - saturation * (1 - fraction));
      switch (sector) {
        case 0:
          red = brightness;
          green = t;
          blue = p;
          break;
        case 1:
          red = q;
          green = brightness;
          blue = p;
          break;
        case 2:
          red = p;
          green = brightness;
          blue = t;
          break;
        case 3:
          red = p;
          green = q;
          blue = brightness;
          break;
        case 4:
          red = t;
          green = p;
          blue = brightness;
          break;
        default: // case 5:
          red = brightness;
          green = p;
          blue = q;
          break;
      }
    }
    return new HueColor(hue: hue, saturation: saturation, brightness: brightness, red: red, green: green, blue: blue);
  }

  /// Converts rgb values to a color temperature.
  ///
  /// returns an [HueColor] with the [red], [green], [blue] values ranging from 0 to 1 converted to
  /// a color temperature.
  /// Approximation from https://github.com/neilbartlett/color-temperature/blob/master/index.js
  HueColor _rgbToColorTemperature(num red, num green, num blue) {
    num temperature;
    HueColor testRGB;
    var epsilon = 0.4;
    num minTemperature = 2200;
    num maxTemperature = 6500;

    while ((maxTemperature - minTemperature) > epsilon) {
      temperature = (maxTemperature + minTemperature) / 2;
      testRGB = _colorTemperatureToRGB(temperature);
      if ((testRGB.blue / testRGB.red) >= (blue / red)) {
        maxTemperature = temperature;
      } else {
        minTemperature = temperature;
      }
    }
    return new HueColor(temperature: temperature.round(), red: red, green: green, blue: blue);
  }

  /// Converts [ct] to rgb values.
  HueColor ctToRGB(num ct) {
    final temperatureColor = _ctToColorTemperature(ct);
    final rgbColor = _colorTemperatureToRGB(temperatureColor.temperature);
    final hsbColor = _colorTemperatureToHueSaturationBrightness(temperatureColor.temperature);
    final xyColor = rgbToXY(rgbColor.red, rgbColor.green, rgbColor.blue);
    rgbColor.ct = ct;
    rgbColor.temperature = temperatureColor.temperature;
    rgbColor.hue = hsbColor.hue;
    rgbColor.saturation = hsbColor.saturation;
    rgbColor.brightness = hsbColor.brightness;
    rgbColor.xy = xyColor.xy;
    return rgbColor;
  }

  /// Converts [red], [green], [blue] values to CT
  HueColor rgbToCT(num red, num green, num blue) {
    final rgbColor = _rgbToColorTemperature(red, green, blue);
    final ctColor = _colorTemperatureToCT(rgbColor.temperature);
    rgbColor.ct = ctColor.ct;
    return rgbColor;
  }

  /// Converts a color temperature to rgb values.
  ///
  /// returns an [HueColor] with a color [temperature] ranging from 1000 to 6000 converted to red, green, blue values.
  /// Sources: http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/ and
  /// https://github.com/neilbartlett/color-temperature/blob/master/index.js
  HueColor _colorTemperatureToRGB(num temperature) {
    var red, green, blue;

    temperature = temperature / 100;
    if (temperature <= 66) {
      red = /*255;*/ 165 + 90 * (temperature / 66);
    } else {
      red = temperature - 60;
      red = 329.698727466 * math.pow(red, -0.1332047592);
      if (red < 0) {
        red = 0;
      }
      if (red > 255) {
        red = 255;
      }
    }
    if (temperature <= 66) {
      green = temperature;
      green = 99.4708025861 * math.log(green) - 161.1195681661;
      if (green < 0) {
        green = 0;
      }
      if (green > 255) {
        green = 255;
      }
    } else {
      green = temperature - 60;
      green = 288.1221695283 * math.pow(green, -0.0755148492);
      if (green < 0) {
        green = 0;
      }
      if (green > 255) {
        green = 255;
      }
    }
    if (temperature >= 66) {
      blue = 255;
    } else {
      if (temperature <= 19) {
        blue = 0;
      } else {
        blue = temperature - 10;
        blue = 138.5177312231 * math.log(blue) - 305.0447927307;
        if (blue < 0) {
          blue = 0;
        }
        if (blue > 255) {
          blue = 255;
        }
      }
    }
    return new HueColor(red: red / 255, green: green / 255, blue: blue / 255, temperature: temperature.toInt());
  }

  /// Converts rgb values to xy
  ///
  /// returns an [HueColor] with the [red], [green], [blue] values ranging from 0 to 1 converted to xy
  /// Source: https://github.com/PhilipsHue/PhilipsHueSDK-iOS-OSX/blob/master/ApplicationDesignNotes/RGB%20to%20xy%20Color%20conversion.md
  HueColor rgbToXY(num red, num green, num blue) {
    // Apply gamma correction
    if (red > 0.04045) {
      red = math.pow((red + 0.055) / (1.055), 2.4);
    } else {
      red = red / 12.92;
    }
    if (green > 0.04045) {
      green = math.pow((green + 0.055) / (1.055), 2.4);
    } else {
      green = green / 12.92;
    }
    if (blue > 0.04045) {
      blue = math.pow((blue + 0.055) / (1.055), 2.4);
    } else {
      blue = blue / 12.92;
    }
    // RGB to XYZ [M] for Wide RGB D65, http://www.developers.meethue.com/documentation/color-conversions-rgb-xy
    var x = red * 0.664511 + green * 0.154324 + blue * 0.162028;
    var y = red * 0.283881 + green * 0.668433 + blue * 0.047685;
    var z = red * 0.000088 + green * 0.072310 + blue * 0.986039;
    // But we don't want Capital X,Y,Z you want lowercase [x,y] (called the color point) as per:
    if ((x + y + z) == 0) {
      return new HueColor(xy: [0, 0]);
    }
    return new HueColor(xy: [x / (x + y + z), y / (x + y + z)]);
  }

  /// Converts [x],[y] with an optional [brightness] to rgb values
  HueColor xyToRGB(num x, num y, [num brightness]) {
    final rgbColor = _xyToRGB(x, y, brightness);
    final temperatureColor = _rgbToColorTemperature(rgbColor.red, rgbColor.green, rgbColor.blue);
    final ctColor = _colorTemperatureToCT(temperatureColor.temperature);
    final hsbColor = _colorTemperatureToHueSaturationBrightness(temperatureColor.temperature);
    rgbColor.ct = ctColor.ct;
    rgbColor.temperature = temperatureColor.temperature;
    rgbColor.hue = hsbColor.hue;
    rgbColor.saturation = hsbColor.saturation;
    rgbColor.brightness = hsbColor.brightness;
    return rgbColor;
  }

  /// Converts xy values to red, green and blue
  ///
  /// returns a [HueColor] with the [x] and [y] with an optional [brightness] converted to red, green and blue values ranging from 0 to 1
  //. Source: https://github.com/PhilipsHue/PhilipsHueSDK-iOS-OSX/blob/master/ApplicationDesignNotes/RGB%20to%20xy%20Color%20conversion.md
  HueColor _xyToRGB(num x, num y, [num brightness]) {
    brightness = brightness ?? 1.0; // Default full brightness
    var z = 1.0 - x - y;
    var Y = brightness;
    var X = (Y / y) * x;
    var Z = (Y / y) * z;
    // XYZ to RGB [M]-1 for Wide RGB D65, http://www.developers.meethue.com/documentation/color-conversions-rgb-xy
    num red = X * 1.656492 - Y * 0.354851 - Z * 0.255038;
    num green = -X * 0.707196 + Y * 1.655397 + Z * 0.036152;
    num blue = X * 0.051713 - Y * 0.121364 + Z * 1.011530;
    // Limit RGB on [0..1]
    if (red > blue && red > green && red > 1.0) {
      // Red is too big
      green = green / red;
      blue = blue / red;
      red = 1.0;
    }
    if (red < 0) {
      red = 0;
    }
    if (green > blue && green > red && green > 1.0) {
      // Green is too big
      red = red / green;
      blue = blue / green;
      green = 1.0;
    }
    if (green < 0) {
      green = 0;
    }
    if (blue > red && blue > green && blue > 1.0) {
      // Blue is too big
      red = red / blue;
      green = green / blue;
      blue = 1.0;
    }
    if (blue < 0) {
      blue = 0;
    }
    // Apply reverse gamma correction
    if (red <= 0.0031308) {
      red = red * 12.92;
    } else {
      red = 1.055 * math.pow(red, (1.0 / 2.4)) - 0.055;
    }
    if (green <= 0.0031308) {
      green = green * 12.92;
    } else {
      green = 1.055 * math.pow(green, (1.0 / 2.4)) - 0.055;
    }
    if (blue <= 0.0031308) {
      blue = blue * 12.92;
    } else {
      blue = 1.055 * math.pow(blue, (1.0 / 2.4)) - 0.055;
    }
    // Limit RGB on [0..1]
    if (red > blue && red > green && red > 1.0) {
      // Red is too big
      green = green / red;
      blue = blue / red;
      red = 1.0;
    }
    if (red < 0) {
      red = 0;
    }
    if (green > blue && green > red && green > 1.0) {
      // Green is too big
      red = red / green;
      blue = blue / green;
      green = 1.0;
    }
    if (green < 0) {
      green = 0;
    }
    if (blue > red && blue > green && blue > 1.0) {
      // Blue is too big
      red = red / blue;
      green = green / blue;
      blue = 1.0;
    }
    if (blue < 0) {
      blue = 0;
    }
    return new HueColor(red: red, green: green, blue: blue, xy: [x, y]);
  }

  /// Converts a color temperature to hue, saturation and brightness values
  ///
  /// returns a [HueColor] with the hue ranging from 0 to 360, saturation and brightness both ranging from 0 to 1 converted from
  /// a color [temperature]
  HueColor _colorTemperatureToHueSaturationBrightness(num temperature) {
    var rgb = _colorTemperatureToRGB(temperature);
    return rgbToHueSaturationBrightness(rgb.red, rgb.green, rgb.blue);
  }

  /// Converts a CT in Mired (micro reciprocal degree) to a color temperature
  ///
  /// returns a [HueColor] with [ct] converted to a color temperature
  HueColor _ctToColorTemperature(num ct) {
    return new HueColor(temperature: (1000000 / ct).round());
  }

  /// Converts a color temperature to CT in Mired (micro reciprocal degree)
  ///
  /// returns a [HueColor] with color [temperature] to CT in Mired (micro reciprocal degree)
  HueColor _colorTemperatureToCT(num temperature) {
    return new HueColor(ct: (1000000 / temperature).round());
  }
}