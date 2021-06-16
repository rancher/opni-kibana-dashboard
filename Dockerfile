FROM python:3.8-slim
COPY ./ /app/

RUN chmod a+rwx -R /app
WORKDIR /app

RUN pip install --no-cache-dir -r requirements.txt
CMD ["bash", "setup_dashbaord_and_es_ism.sh"]
