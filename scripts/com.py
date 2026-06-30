#!/usr/bin/env python3

import sys
import argparse
import numpy as np
from stl import mesh


def center_at_com(input_file, output_file):
    your_mesh = mesh.Mesh.from_file(input_file)
    volume, cog, inertia = your_mesh.get_mass_properties()

    print("Volume = {0}".format(volume))
    print("Position of the center of gravity (COG) = {0}".format(cog))
    print("Inertia matrix at expressed at the COG = {0}".format(inertia[0, :]))
    print(" {0}".format(inertia[1, :]))
    print(" {0}".format(inertia[2, :]))

    your_mesh.translate(-cog)
    your_mesh.save(output_file)
    print("Saved centered mesh to {0}".format(output_file))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Center an STL file at its center of mass."
    )
    parser.add_argument("input", help="Input STL file")
    parser.add_argument(
        "-o",
        "--output",
        default="new.stl",
        help="Output STL file (default: new.stl)",
    )
    args = parser.parse_args()
    center_at_com(args.input, args.output)
