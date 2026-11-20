.pragma library
// Создано tools/build.py из skins/*.json. Руками не править.
var data = {
 "order": [
  "keeper",
  "archive1",
  "archive2"
 ],
 "skins": {
  "keeper": {
   "title": "Смотритель",
   "note": "Трафаретная печать в три краски: красный, чёрный и костяной. Светлый вариант — на бумаге, тёмный — на красном листе.",
   "shader": "poster",
   "irisRadius": 0.86,
   "restLid": 0.2,
   "motion": {
    "omega": 22,
    "blinkClose": 75,
    "blinkHold": 45,
    "blinkOpen": 150
   },
   "themeMap": [
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    ""
   ],
   "variants": {
    "light": {
     "title": "На бумаге",
     "page": {
      "bg": "#E6DCC8",
      "surface": "#F5EEE1",
      "text": "#140A0A",
      "muted": "#4A4038",
      "a1": "#B3151C",
      "a2": "#140A0A",
      "a3": "#8F1218",
      "outline": "#8C7F6C"
     },
     "colors": [
      "#E6DCC8",
      "#FDFAF2",
      "#C4161C",
      "#0A0505",
      "#FDFAF2",
      "#0A0505",
      "#C4161C",
      "#0A0505"
     ],
     "p1": [
      0,
      1,
      0,
      0
     ]
    },
    "dark": {
     "title": "На красном",
     "page": {
      "bg": "#B4151C",
      "surface": "#120909",
      "text": "#ECE3D2",
      "muted": "#B5AA98",
      "a1": "#E23A40",
      "a2": "#ECE3D2",
      "a3": "#8F1218",
      "outline": "#6B4A46"
     },
     "colors": [
      "#B4151C",
      "#ECE3D2",
      "#0A0505",
      "#0A0505",
      "#ECE3D2",
      "#0A0505",
      "#760B11",
      "#B4151C"
     ],
     "p1": [
      0,
      0,
      0,
      0
     ]
    }
   },
   "shape": {
    "type": "lens"
   },
   "character": {
    "tempo": 1.0,
    "omega": 1.0,
    "lag": 0,
    "blink": [
     2600,
     6800
    ],
    "blinkKind": "lid",
    "acts": {
     "laugh": 3,
     "surprise": 2.5,
     "fear": 2,
     "angry": 2,
     "sad": 2.5,
     "disgust": 2,
     "fly": 3,
     "hunt": 2.5,
     "contest": 2,
     "spin": 2,
     "roll": 2,
     "suspect": 2,
     "around": 2.5,
     "dream": 2.5,
     "yawn": 3,
     "nod": 4,
     "shake": 2
    }
   }
  },
  "archive1": {
   "title": "Архив I",
   "note": "Самый первый глаз, январь 2026 года: три ровных пятна, веки цвета фона. Оставлен на память.",
   "shader": "archive1",
   "irisRadius": 0.905,
   "restLid": 0.05,
   "shape": {
    "type": "lens",
    "w": 2.8,
    "hu": 0.72,
    "hl": 0.72
   },
   "character": {
    "plain": true,
    "dozeAfter": 120,
    "drowsyLid": 0.95,
    "actGap": [
     9000,
     20000
    ],
    "tempo": 1.0,
    "omega": 0.8,
    "lag": 0.02,
    "blink": [
     4000,
     9000
    ],
    "blinkKind": "lid",
    "acts": {
     "sweep": 1
    }
   },
   "themeMap": [
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    ""
   ],
   "variants": {
    "dark": {
     "title": "Как был",
     "page": {
      "bg": "#151410",
      "surface": "#1D1B17",
      "text": "#EDE6E0",
      "muted": "#9A938C",
      "a1": "#F39C9E",
      "a2": "#7FD6B2",
      "a3": "#C9B7AE",
      "outline": "#3D3532"
     },
     "colors": [
      "#151410",
      "#3D3532",
      "#F39C9E",
      "#F4EEEE",
      "#F4EEEE",
      "#3D3532",
      "#3D3532",
      "#F39C9E"
     ]
    },
    "light": {
     "title": "Светлый",
     "page": {
      "bg": "#F1ECE6",
      "surface": "#FAF7F3",
      "text": "#221E1B",
      "muted": "#6E655E",
      "a1": "#C2535E",
      "a2": "#2F8A68",
      "a3": "#7A6257",
      "outline": "#CFC5BC"
     },
     "colors": [
      "#F1ECE6",
      "#DDD3CB",
      "#EE8C93",
      "#1F1B19",
      "#1F1B19",
      "#DDD3CB",
      "#DDD3CB",
      "#EE8C93"
     ]
    }
   }
  },
  "archive2": {
   "title": "Архив II",
   "note": "Второй глаз, Vesper Eye 0.1, осень 2026 года: костяной белок, гранатовая радужка, тонкий контур. Оставлен на память.",
   "shader": "archive2",
   "irisRadius": 0.804,
   "restLid": 0.04,
   "shape": {
    "type": "lens",
    "w": 2.8,
    "hu": 0.66,
    "hl": 0.66
   },
   "character": {
    "plain": true,
    "dozeAfter": 120,
    "drowsyLid": 0.95,
    "actGap": [
     9000,
     20000
    ],
    "tempo": 1.0,
    "omega": 0.8,
    "lag": 0.02,
    "blink": [
     4000,
     9000
    ],
    "blinkKind": "lid",
    "acts": {
     "sweep": 1
    }
   },
   "themeMap": [
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    ""
   ],
   "variants": {
    "dark": {
     "title": "Как был",
     "page": {
      "bg": "#0D0B10",
      "surface": "#17121A",
      "text": "#E8DDCF",
      "muted": "#B6A6B1",
      "a1": "#CC6B7C",
      "a2": "#C6A36D",
      "a3": "#83AAA1",
      "outline": "#574650"
     },
     "colors": [
      "#17121A",
      "#C3B4A4",
      "#75263D",
      "#08070B",
      "#F6E8DE",
      "#CFC3BC",
      "#AA3758",
      "#451624"
     ]
    },
    "light": {
     "title": "Светлый",
     "page": {
      "bg": "#EDE5DA",
      "surface": "#F8F3EB",
      "text": "#1E1519",
      "muted": "#6F6166",
      "a1": "#8A2D48",
      "a2": "#8A6A2F",
      "a3": "#3F7468",
      "outline": "#C9BBAE"
     },
     "colors": [
      "#E2D7CA",
      "#FBF6EE",
      "#8A2D48",
      "#140E12",
      "#FFF8F0",
      "#5A4640",
      "#C24D6E",
      "#541B2D"
     ]
    }
   }
  }
 }
};
