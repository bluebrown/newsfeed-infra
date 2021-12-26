FROM clojure:openjdk-17-lein-buster as builder
RUN apt-get update -y && apt-get install make
WORKDIR /src
COPY . ./
RUN make libs && make

FROM openjdk:17-slim-buster
RUN adduser --disabled-password --gecos "" --uid 101221 java
ARG TARGET="newsfeed"
ENV TARGET="$TARGET"
COPY --chown=101221:101221 --from=builder "/src/build/${TARGET}.jar" ./
CMD java -jar ${TARGET}.jar
USER java
EXPOSE 8080
