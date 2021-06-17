FROM python:3.8-slim

RUN apt-get update && apt-get install -y \
  curl \
  && rm -rf /var/lib/apt/lists/*

COPY ./ /app/

RUN chmod a+rwx -R /app
WORKDIR /app

RUN pip install --no-cache-dir -r requirements.txt
CMD ["bash", "setup_dashbaord_and_es_ism.sh"]
