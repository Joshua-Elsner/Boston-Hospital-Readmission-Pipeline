# 1. Base Image: Use the slim Python 3.11 image to keep the container lightweight
FROM python:3.11-slim

# 2. System Dependencies: Install git (often required by dbt packages)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# 3. Working Directory: Set the internal container path
WORKDIR /opt/dagster/app

# 4. Dependencies: Copy your orchestration requirements and install them
COPY orchestration/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 5. Application Code: Copy the entire project into the container
COPY . .

# 6. Execution Directory: Move into the orchestration folder where your pipeline module lives
WORKDIR /opt/dagster/app/orchestration

# 7. Port: Expose port 3000 for the Dagster UI
EXPOSE 3000

# 8. Command: Boot up the development suite and point it to your Python module
CMD ["dagster", "dev", "-h", "0.0.0.0", "-p", "3000", "-m", "my_pipeline"]