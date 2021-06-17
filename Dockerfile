FROM curlimages/curl:7.77.0

COPY ./ /app/

WORKDIR /app

CMD ["sh", "setup_dashbaord_and_es_ism.sh"]
