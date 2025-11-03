FROM python:3.9.11

WORKDIR /usr/src/app

RUN pip install awscli
RUN aws --version

RUN pip install httpx==0.15.3 # oh no we might have cves ;-)

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

RUN echo "Arnica is awesome!!!"

COPY . .

RUN cat /etc/os-release

CMD ["echo", "hello", "world", "Sonk"]

