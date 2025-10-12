import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev')
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'postgresql://postgres:1234@localhost:5432/truthliesdetector')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
