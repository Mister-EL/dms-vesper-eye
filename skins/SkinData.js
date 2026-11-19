.pragma library
// Создано tools/build.py из skins/*.json. Руками не править.
var data = {
 "order": [
  "pearl",
  "signal",
  "lattice",
  "neon",
  "eclipse",
  "vesper"
 ],
 "skins": {
  "pearl": {
   "title": "Перламутр",
   "note": "Пастель: белый, розовый, голубой. Опаловая радужка с переливом.",
   "shader": "pearl",
   "irisRadius": 0.9,
   "motion": {
    "omega": 17,
    "blinkClose": 110,
    "blinkHold": 40,
    "blinkOpen": 240
   },
   "variants": {
    "dark": {
     "title": "Сумерки",
     "page": {
      "bg": "#0C0A12",
      "surface": "#15121E",
      "text": "#F3EDF6",
      "muted": "#B9B0CC",
      "a1": "#F5A8C6",
      "a2": "#A8D2F5",
      "a3": "#CDBEF5",
      "outline": "#6F6788"
     },
     "colors": [
      "#FBF6FA",
      "#CBBFE2",
      "#8EC5F2",
      "#C7B5F1",
      "#F3A6C6",
      "#2F2A45",
      "#17131F",
      "#E9B8A6"
     ]
    },
    "light": {
     "title": "День",
     "page": {
      "bg": "#F8F4F6",
      "surface": "#FFFFFF",
      "text": "#2F2A45",
      "muted": "#6A6382",
      "a1": "#B84877",
      "a2": "#3674B4",
      "a3": "#6F5CB8",
      "outline": "#B9ACC0"
     },
     "colors": [
      "#FDFBFC",
      "#D6CBE8",
      "#8EC5F2",
      "#C7B5F1",
      "#F3A6C6",
      "#2F2A45",
      "#FBF7F8",
      "#E9B8A6"
     ]
    }
   },
   "restLid": 0.1,
   "themeMap": [
    "",
    "",
    "secondary",
    "tertiary",
    "primary",
    "",
    "surface",
    "primary"
   ]
  },
  "signal": {
   "title": "Сигнал",
   "note": "Чёрный, белый, серый и одна ярко-зелёная радужка. Чертёж и прибор.",
   "shader": "signal",
   "irisRadius": 0.74,
   "restLid": 0.0,
   "motion": {
    "omega": 30,
    "blinkClose": 60,
    "blinkHold": 20,
    "blinkOpen": 120
   },
   "themeMap": [
    "surfaceText",
    "",
    "primary",
    "",
    "",
    "outline",
    "",
    "primary"
   ],
   "variants": {
    "dark": {
     "title": "Ночь",
     "page": {
      "bg": "#000000",
      "surface": "#0E0E10",
      "text": "#F4F4F5",
      "muted": "#A1A1AA",
      "a1": "#3DFF6E",
      "a2": "#D4D4D8",
      "a3": "#8E8E96",
      "outline": "#5E5E66"
     },
     "colors": [
      "#F4F4F5",
      "#000000",
      "#3DFF6E",
      "#000000",
      "#FFFFFF",
      "#6B6B73",
      "#000000",
      "#1F8A3C"
     ]
    },
    "light": {
     "title": "Бумага",
     "page": {
      "bg": "#EDEDEE",
      "surface": "#FFFFFF",
      "text": "#0B0B0C",
      "muted": "#55555C",
      "a1": "#008A34",
      "a2": "#3F3F46",
      "a3": "#71717A",
      "outline": "#8A8A93"
     },
     "colors": [
      "#0B0B0C",
      "#FFFFFF",
      "#3DFF6E",
      "#0B0B0C",
      "#FFFFFF",
      "#8A8A93",
      "#EDEDEE",
      "#1F8A3C"
     ]
    }
   }
  },
  "lattice": {
   "title": "Сеть",
   "note": "Глаз, сплетённый из узлов и связей: созвездие, карта маршрутов. Пакет бежит к корневому узлу.",
   "shader": "lattice",
   "irisRadius": 0.78,
   "restLid": 0.0,
   "motion": {
    "omega": 18,
    "blinkClose": 100,
    "blinkHold": 40,
    "blinkOpen": 220
   },
   "themeMap": [
    "primary",
    "surfaceText",
    "tertiary",
    "secondary",
    "",
    "",
    "outline",
    "primary"
   ],
   "variants": {
    "dark": {
     "title": "Магистраль",
     "page": {
      "bg": "#03060C",
      "surface": "#0A111D",
      "text": "#E4EEFF",
      "muted": "#93A8C9",
      "a1": "#5CC8FF",
      "a2": "#FFC46B",
      "a3": "#6DFFD0",
      "outline": "#4A6088"
     },
     "colors": [
      "#5CC8FF",
      "#E3EEFF",
      "#FFC46B",
      "#6DFFD0",
      "#123E73",
      "#000000",
      "#2F6DB5",
      "#7CCBFF"
     ]
    }
   }
  },
  "neon": {
   "title": "Неон-нуар",
   "note": "Киберпанк: оптический имплант с диафрагмой. Циан и маджента на чёрном стекле.",
   "shader": "neon",
   "irisRadius": 0.74,
   "restLid": 0.0,
   "motion": {
    "omega": 26,
    "blinkClose": 70,
    "blinkHold": 30,
    "blinkOpen": 150
   },
   "themeMap": [
    "",
    "secondary",
    "primary",
    "tertiary",
    "",
    "",
    "",
    ""
   ],
   "variants": {
    "dark": {
     "title": "Ночной город",
     "page": {
      "bg": "#05030A",
      "surface": "#0E0818",
      "text": "#ECE8FF",
      "muted": "#A99FD0",
      "a1": "#FF3D9A",
      "a2": "#2DE2FF",
      "a3": "#FFE45C",
      "outline": "#5B4A86"
     },
     "colors": [
      "#0E0818",
      "#2DE2FF",
      "#FF3D9A",
      "#8A5CFF",
      "#FFE45C",
      "#FF2D55",
      "#0B0714",
      "#2A2148"
     ]
    }
   }
  },
  "eclipse": {
   "title": "Затмение",
   "note": "Полное солнечное затмение: чёрный диск Луны, жемчужная корона и серп Солнца при взгляде в сторону.",
   "shader": "eclipse",
   "irisRadius": 0.9,
   "restLid": 0.08,
   "motion": {
    "omega": 14,
    "blinkClose": 130,
    "blinkHold": 50,
    "blinkOpen": 280
   },
   "themeMap": [
    "",
    "",
    "primary",
    "",
    "",
    "",
    "tertiary",
    ""
   ],
   "variants": {
    "dark": {
     "title": "Полная фаза",
     "page": {
      "bg": "#000000",
      "surface": "#0A0B10",
      "text": "#F1EEE6",
      "muted": "#A5A7B5",
      "a1": "#F3DDAA",
      "a2": "#FF6F8B",
      "a3": "#9DB4FF",
      "outline": "#5F6274"
     },
     "colors": [
      "#F6F1E7",
      "#F3DDAA",
      "#FF5E7E",
      "#0B1020",
      "#020308",
      "#000000",
      "#9DB4FF",
      "#04050A"
     ]
    }
   }
  },
  "vesper": {
   "title": "Веспер",
   "note": "Прежний готический вид: винный гранат, кость и потемневшая латунь.",
   "shader": "vesper",
   "irisRadius": 0.92,
   "restLid": 0.1,
   "motion": {
    "omega": 20,
    "blinkClose": 95,
    "blinkHold": 30,
    "blinkOpen": 175
   },
   "themeMap": [
    "",
    "",
    "",
    "primary",
    "secondary",
    "",
    "surface",
    "primary"
   ],
   "variants": {
    "dark": {
     "title": "Sanguine Ivory",
     "page": {
      "bg": "#0D0B10",
      "surface": "#17121A",
      "text": "#E8DDCF",
      "muted": "#B6A6B1",
      "a1": "#CC6B7C",
      "a2": "#C6A36D",
      "a3": "#A28DB8",
      "outline": "#796572"
     },
     "colors": [
      "#D2C4AE",
      "#6B5960",
      "#2A0F1A",
      "#8A324C",
      "#C6A36D",
      "#08070B",
      "#17121A",
      "#CC6B7C"
     ]
    }
   }
  }
 }
};
