-- The asteroid belt, made by make-belt.py: don't edit.
-- Osculating elements, heliocentric, ecliptic and equinox of J2000 (degrees, AU),
-- from the Minor Planet Center via Stellarium's ssystem_minor.ini; diameters (km)
-- from memory (see make-belt.py).
return {
  EPOCH = 2461000.5,  -- JD (TT), 2025-11-21
  list = {
    { no = 1, name = "Ceres", d = 939.4, H = 3.34, a = 2.7656157, e = 0.0795763, i = 10.58789, node = 80.24963, peri = 73.29974, M = 231.53975, found = "1801-01-01", by = "G. Piazzi", engine = true },
    { no = 4, name = "Vesta", d = 525.4, H = 3.25, a = 2.3615413, e = 0.0901676, i = 7.14406, node = 103.70232, peri = 151.53712, M = 26.80968, found = "1807-03-29", by = "H.W. Olbers", engine = true },
    { no = 2, name = "Pallas", d = 513, H = 4.11, a = 2.7699258, e = 0.230643, i = 34.92833, node = 172.88859, peri = 310.9334, M = 211.52977, found = "1802-03-28", by = "H.W. Olbers", engine = true },
    { no = 10, name = "Hygiea", d = 434, H = 5.64, a = 3.1475914, e = 0.1082238, i = 3.83294, node = 283.12164, peri = 312.60583, M = 216.69031, found = "1849-04-12", by = "A. de Gasparis", engine = true },
    { no = 704, name = "Interamnia", d = 332, H = 6.33, a = 3.0562188, e = 0.1552478, i = 17.31546, node = 280.16607, peri = 94.10696, M = 184.2054, found = "1910-10-02", by = "V. Cerulli" },
    { no = 52, name = "Europa", d = 315, H = 6.65, a = 3.0921934, e = 0.1120016, i = 7.48092, node = 128.57908, peri = 342.95841, M = 312.52763, found = "1858-02-04", by = "H. Goldschmidt" },
    { no = 511, name = "Davida", d = 298, H = 6.41, a = 3.1636191, e = 0.1896285, i = 15.95005, node = 107.55547, peri = 336.66693, M = 35.24756, found = "1903-05-30", by = "R.S. Dugan" },
    { no = 87, name = "Sylvia", d = 271, H = 6.93, a = 3.4845188, e = 0.0943375, i = 10.87248, node = 73.01149, peri = 265.82654, M = 94.95961, found = "1866-05-16", by = "N.R. Pogson" },
    { no = 15, name = "Eunomia", d = 268, H = 5.42, a = 2.6421861, e = 0.1877813, i = 11.76143, node = 292.88123, peri = 98.5072, M = 113.72578, found = "1851-07-29", by = "A. de Gasparis" },
    { no = 31, name = "Euphrosyne", d = 268, H = 6.81, a = 3.1615053, e = 0.2159207, i = 26.31223, node = 30.7959, peri = 61.97074, M = 147.89313, found = "1854-09-01", by = "J. Ferguson" },
    { no = 65, name = "Cybele", d = 263, H = 6.83, a = 3.4076673, e = 0.1277298, i = 3.56495, node = 155.0988, peri = 104.13941, M = 272.63269, found = "1861-03-08", by = "E.W. Tempel" },
    { no = 3, name = "Juno", d = 254, H = 5.18, a = 2.6708791, e = 0.2558258, i = 12.98604, node = 169.81989, peri = 247.88367, M = 217.59095, found = "1804-09-01", by = "K. Harding", engine = true },
    { no = 107, name = "Camilla", d = 254, H = 7.1, a = 3.4930911, e = 0.0664514, i = 9.99866, node = 172.50627, peri = 303.73826, M = 332.54454, found = "1868-11-17", by = "N.R. Pogson" },
    { no = 324, name = "Bamberga", d = 228, H = 7.19, a = 2.6823713, e = 0.3404491, i = 11.09615, node = 327.82765, peri = 44.20082, M = 268.84874, found = "1892-02-25", by = "J. Palisa" },
    { no = 451, name = "Patientia", d = 225, H = 6.78, a = 3.0641587, e = 0.069636, i = 15.20639, node = 88.99603, peri = 337.19308, M = 184.50431, found = "1899-12-04", by = "A. Charlois" },
    { no = 16, name = "Psyche", d = 222, H = 6.2, a = 2.9233145, e = 0.1343462, i = 3.09729, node = 150.00988, peri = 229.75341, M = 40.63883, found = "1852-03-17", by = "A. de Gasparis" },
    { no = 88, name = "Thisbe", d = 218, H = 7.25, a = 2.7669638, e = 0.1652895, i = 5.22642, node = 276.32467, peri = 36.9356, M = 201.53354, found = "1866-06-15", by = "C.H.F. Peters" },
    { no = 48, name = "Doris", d = 216, H = 7.12, a = 3.1128708, e = 0.0662636, i = 6.55777, node = 183.42798, peri = 251.35542, M = 141.74525, found = "1857-09-19", by = "H. Goldschmidt" },
    { no = 375, name = "Ursula", d = 216, H = 7.48, a = 3.1274075, e = 0.1023705, i = 15.94056, node = 336.38214, peri = 341.42449, M = 4.78044, found = "1893-09-18", by = "A. Charlois" },
    { no = 7, name = "Iris", d = 214, H = 5.67, a = 2.386529, e = 0.2302133, i = 5.51881, node = 259.49459, peri = 145.48204, M = 61.72502, found = "1847-08-13", by = "J.R. Hind" },
    { no = 19, name = "Fortuna", d = 211, H = 7.49, a = 2.4420634, e = 0.1580362, i = 1.57331, node = 211.00111, peri = 182.51542, M = 96.49967, found = "1852-08-22", by = "J.R. Hind" },
    { no = 423, name = "Diotima", d = 208, H = 7.38, a = 3.0667835, e = 0.0338729, i = 11.24258, node = 69.349, peri = 199.08736, M = 142.07248, found = "1896-12-07", by = "A. Charlois" },
    { no = 532, name = "Herculina", d = 207, H = 5.92, a = 2.7700338, e = 0.1801823, i = 16.2993, node = 107.41125, peri = 76.65843, M = 136.49502, found = "1904-04-20", by = "M.F. Wolf" },
    { no = 29, name = "Amphitrite", d = 204, H = 5.97, a = 2.5541211, e = 0.0733503, i = 6.07744, node = 356.25475, peri = 61.90576, M = 145.10816, found = "1854-03-01", by = "A. Marth" },
    { no = 94, name = "Aurora", d = 204, H = 7.71, a = 3.1563619, e = 0.0963849, i = 7.96978, node = 2.51806, peri = 60.52691, M = 10.64458, found = "1867-09-06", by = "J.C. Watson" },
    { no = 13, name = "Egeria", d = 203, H = 6.91, a = 2.5762588, e = 0.084682, i = 16.52553, node = 43.17717, peri = 79.06456, M = 40.99101, found = "1850-11-02", by = "A. de Gasparis" },
    { no = 45, name = "Eugenia", d = 202, H = 7.76, a = 2.7215823, e = 0.0821724, i = 6.60564, node = 147.55501, peri = 87.29355, M = 206.55227, found = "1857-06-27", by = "H. Goldschmidt" },
    { no = 130, name = "Elektra", d = 199, H = 7.46, a = 3.1239698, e = 0.2094513, i = 22.78346, node = 144.97197, peri = 237.93444, M = 13.43432, found = "1873-02-17", by = "C.H.F. Peters" },
    { no = 24, name = "Themis", d = 198, H = 7.22, a = 3.1432542, e = 0.115343, i = 0.7367, node = 36.39207, peri = 109.10768, M = 56.76453, found = "1853-04-05", by = "A. de Gasparis" },
    { no = 121, name = "Hermione", d = 194, H = 7.4, a = 3.4569988, e = 0.1246355, i = 7.5663, node = 72.87519, peri = 297.01608, M = 227.97435, found = "1872-05-12", by = "J.C. Watson" },
  },
}
