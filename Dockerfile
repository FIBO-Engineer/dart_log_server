FROM ghcr.io/cirruslabs/flutter:3.29.3

RUN mkdir /app

WORKDIR /app

COPY . .

RUN flutter pub get

WORKDIR /app/bin

RUN chmod +x ./main.dart

EXPOSE 6008

# Start the Dart server
CMD ["dart", "run", "main.dart"]