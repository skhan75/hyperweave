from hilbertcurve.hilbertcurve import HilbertCurve

# Set order and dimensions
p = 2  # Order of the Hilbert curve
n = 3  # Number of dimensions (3D)

# Create a Hilbert curve instance
hilbert_curve = HilbertCurve(p, n)

# Index to test
index = 35

# Get the coordinates for the given index
coords = hilbert_curve.point_from_distance(index)
print(f"Index {index} maps to coordinates {coords}")
