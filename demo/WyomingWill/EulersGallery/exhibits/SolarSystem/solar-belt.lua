-- The asteroid belt, made by make-belt.py: don't edit.
-- Osculating elements, heliocentric, ecliptic and equinox of J2000 (degrees, AU),
-- the Minor Planet Center's via Stellarium's ssystem_minor.ini; diameters (d, km)
-- and their sigmas JPL SBDB's (belt/sbdb-largest-40.txt, fetched 2026-10-18).
return {
  EPOCH = 2461000.5,  -- JD (TT), 2025-11-21
  list = {
    { no = 1, name = "Ceres", d = 939.4, sigma = 0.2, H = 3.34, a = 2.7656157, e = 0.0795763, i = 10.58789, node = 80.24963, peri = 73.29974, M = 231.53975, found = "1801-01-01", by = "G. Piazzi", engine = true },
    { no = 4, name = "Vesta", d = 522.77, sigma = 0.1, H = 3.25, a = 2.3615413, e = 0.0901676, i = 7.14406, node = 103.70232, peri = 151.53712, M = 26.80968, found = "1807-03-29", by = "H.W. Olbers", engine = true },
    { no = 2, name = "Pallas", d = 513, sigma = 6, H = 4.11, a = 2.7699258, e = 0.230643, i = 34.92833, node = 172.88859, peri = 310.9334, M = 211.52977, found = "1802-03-28", by = "H.W. Olbers", engine = true },
    { no = 10, name = "Hygiea", d = 407.12, sigma = 6.8, H = 5.64, a = 3.1475914, e = 0.1082238, i = 3.83294, node = 283.12164, peri = 312.60583, M = 216.69031, found = "1849-04-12", by = "A. de Gasparis", engine = true },
    { no = 704, name = "Interamnia", d = 306.313, sigma = 1.03, H = 6.33, a = 3.0562188, e = 0.1552478, i = 17.31546, node = 280.16607, peri = 94.10696, M = 184.2054, found = "1910-10-02", by = "V. Cerulli" },
    { no = 52, name = "Europa", d = 303.918, sigma = 3.5, H = 6.65, a = 3.0921934, e = 0.1120016, i = 7.48092, node = 128.57908, peri = 342.95841, M = 312.52763, found = "1858-02-04", by = "H. Goldschmidt" },
    { no = 511, name = "Davida", d = 270.327, sigma = 1.04, H = 6.41, a = 3.1636191, e = 0.1896285, i = 15.95005, node = 107.55547, peri = 336.66693, M = 35.24756, found = "1903-05-30", by = "R.S. Dugan" },
    { no = 31, name = "Euphrosyne", d = 267.08, sigma = 2.61, H = 6.81, a = 3.1615053, e = 0.2159207, i = 26.31223, node = 30.7959, peri = 61.97074, M = 147.89313, found = "1854-09-01", by = "J. Ferguson" },
    { no = 451, name = "Patientia", d = 253.9, sigma = 2.78, H = 6.78, a = 3.0641587, e = 0.069636, i = 15.20639, node = 88.99603, peri = 337.19308, M = 184.50431, found = "1899-12-04", by = "A. Charlois" },
    { no = 87, name = "Sylvia", d = 253.051, sigma = 2.95, H = 6.93, a = 3.4845188, e = 0.0943375, i = 10.87248, node = 73.01149, peri = 265.82654, M = 94.95961, found = "1866-05-16", by = "N.R. Pogson" },
    { no = 3, name = "Juno", d = 246.596, sigma = 10.59, H = 5.18, a = 2.6708791, e = 0.2558258, i = 12.98604, node = 169.81989, peri = 247.88367, M = 217.59095, found = "1804-09-01", by = "K. Harding", engine = true },
    { no = 65, name = "Cybele", d = 237.26, sigma = 4.2, H = 6.83, a = 3.4076673, e = 0.1277298, i = 3.56495, node = 155.0988, peri = 104.13941, M = 272.63269, found = "1861-03-08", by = "E.W. Tempel" },
    { no = 88, name = "Thisbe", d = 232, sigma = nil, H = 7.25, a = 2.7669638, e = 0.1652895, i = 5.22642, node = 276.32467, peri = 36.9356, M = 201.53354, found = "1866-06-15", by = "C.H.F. Peters" },
    { no = 15, name = "Eunomia", d = 231.689, sigma = 2.23, H = 5.42, a = 2.6421861, e = 0.1877813, i = 11.76143, node = 292.88123, peri = 98.5072, M = 113.72578, found = "1851-07-29", by = "A. de Gasparis" },
    { no = 16, name = "Psyche", d = 222, sigma = nil, H = 6.2, a = 2.9233145, e = 0.1343462, i = 3.09729, node = 150.00988, peri = 229.75341, M = 40.63883, found = "1852-03-17", by = "A. de Gasparis" },
    { no = 324, name = "Bamberga", d = 220.691, sigma = 1.44, H = 7.19, a = 2.6823713, e = 0.3404491, i = 11.09615, node = 327.82765, peri = 44.20082, M = 268.84874, found = "1892-02-25", by = "J. Palisa" },
    { no = 48, name = "Doris", d = 216.473, sigma = 4.76, H = 7.12, a = 3.1128708, e = 0.0662636, i = 6.55777, node = 183.42798, peri = 251.35542, M = 141.74525, found = "1857-09-19", by = "H. Goldschmidt" },
    { no = 375, name = "Ursula", d = 216, sigma = nil, H = 7.48, a = 3.1274075, e = 0.1023705, i = 15.94056, node = 336.38214, peri = 341.42449, M = 4.78044, found = "1893-09-18", by = "A. Charlois" },
    { no = 107, name = "Camilla", d = 210.37, sigma = 8.33, H = 7.1, a = 3.4930911, e = 0.0664514, i = 9.99866, node = 172.50627, peri = 303.73826, M = 332.54454, found = "1868-11-17", by = "N.R. Pogson" },
    { no = 121, name = "Hermione", d = 209, sigma = 4.7, H = 7.4, a = 3.4569988, e = 0.1246355, i = 7.5663, node = 72.87519, peri = 297.01608, M = 227.97435, found = "1872-05-12", by = "J.C. Watson" },
    { no = 117, name = "Lomia", d = 208.974, sigma = 1.21, H = 8.15, a = 2.9918846, e = 0.0229211, i = 14.92192, node = 348.61679, peri = 53.24207, M = 244.39811, found = "1871-09-12", by = "A. Borrelly" },
    { no = 106, name = "Dione", d = 207.869, sigma = 2.16, H = 7.76, a = 3.182491, e = 0.1588532, i = 4.575, node = 61.98311, peri = 331.74654, M = 279.92762, found = "1868-10-10", by = "J.C. Watson" },
    { no = 41, name = "Daphne", d = 205.495, sigma = 1.88, H = 7.58, a = 2.768658, e = 0.270442, i = 15.72829, node = 177.61962, peri = 46.91596, M = 288.43727, found = "1856-05-22", by = "H. Goldschmidt" },
    { no = 94, name = "Aurora", d = 204.89, sigma = 3.6, H = 7.71, a = 3.1563619, e = 0.0963849, i = 7.96978, node = 2.51806, peri = 60.52691, M = 10.64458, found = "1867-09-06", by = "J.C. Watson" },
    { no = 13, name = "Egeria", d = 202.636, sigma = 50.08, H = 6.91, a = 2.5762588, e = 0.084682, i = 16.52553, node = 43.17717, peri = 79.06456, M = 40.99101, found = "1850-11-02", by = "A. de Gasparis" },
    { no = 45, name = "Eugenia", d = 202.327, sigma = 2.17, H = 7.76, a = 2.7215823, e = 0.0821724, i = 6.60564, node = 147.55501, peri = 87.29355, M = 206.55227, found = "1857-06-27", by = "H. Goldschmidt" },
    { no = 19, name = "Fortuna", d = 200, sigma = nil, H = 7.49, a = 2.4420634, e = 0.1580362, i = 1.57331, node = 211.00111, peri = 182.51542, M = 96.49967, found = "1852-08-22", by = "J.R. Hind" },
    { no = 7, name = "Iris", d = 199.83, sigma = 10, H = 5.67, a = 2.386529, e = 0.2302133, i = 5.51881, node = 259.49459, peri = 145.48204, M = 61.72502, found = "1847-08-13", by = "J.R. Hind" },
    { no = 24, name = "Themis", d = 198, sigma = nil, H = 7.22, a = 3.1432542, e = 0.115343, i = 0.7367, node = 36.39207, peri = 109.10768, M = 56.76453, found = "1853-04-05", by = "A. de Gasparis" },
    { no = 154, name = "Bertha", d = 192.611, sigma = 2.19, H = 7.65, a = 3.1931929, e = 0.0770252, i = 21.02228, node = 36.47724, peri = 167.95948, M = 342.6284, found = "1875-11-04", by = "P.M. Henry" },
  },
}
