
class HexRGBConverter
  convertHexFromRGB: (r, g, b) ->
    hexify = (n) ->
      if (s = n.toString 16).length < 2 then '0' + s else s

    '#' + hexify(r) + hexify(g) + hexify(b)

  convertRGBFromHex: (hex) ->
    hex = hex.replace(/#/, '') if hex[0] is '#'
    (parseInt(hex.substr(i * 2, 2), 16) for i in [0 ... 3])

  RGBToNum: (r, g, b) ->
    ((r & 0x0ff) << 16) | ((g & 0x0ff) << 8) | (b & 0x0ff)

  numToRGB: (rgbInteger) ->
    [
      (rgbInteger >> 16) & 0x0ff,
      (rgbInteger >> 8) & 0x0ff,
      (rgbInteger) & 0x0ff
    ]

  hexToNum: (hex) ->
    @RGBToNum.apply @, @convertRGBFromHex hex

  numToHex: (rgbInteger) ->
    @convertHexFromRGB.apply @, @numToRGB rgbInteger
