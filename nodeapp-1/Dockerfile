FROM node:16-alpine

MAINTAINER itsvenkatesh@gmail.com

WORKDIR /usr/src/app


COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 8081

CMD [ "node", "server.js" ]


