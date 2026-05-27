# Task 3: Write a cache-friendly Dockerfile.
#
# Requirements (in order):
# 1. Use python:3.11-slim as the base image.
# 2. Copy requirements.txt BEFORE copying source code.
# 3. Install dependencies from requirements.txt.
# 4. Copy src/ into the image.
# 5. Set the CMD to run the pipeline: python -m src.pipeline
#
# Replace each TODO comment with the correct Dockerfile instruction.

# TODO: set the base image
FROM TODO

WORKDIR /app

# TODO: copy requirements.txt (before source — this keeps the install layer cached)

# TODO: install dependencies

# TODO: copy source code

# TODO: set the command that runs when the container starts
CMD ["TODO"]
