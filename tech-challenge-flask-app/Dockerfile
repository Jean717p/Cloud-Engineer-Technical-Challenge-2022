FROM python:3.10
WORKDIR /usr/src/app
COPY . .
RUN pip install -r requirements.txt
EXPOSE 8000
CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:candidates_app"]