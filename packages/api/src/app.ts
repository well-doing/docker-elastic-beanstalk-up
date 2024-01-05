import express from "express";
import { Pong } from "models";

const app = express();

app.use("/", (_req, res) =>
  res.status(200).send({
    pong: "this pong is coming from api (from version) :D",
  } as Pong)
);

export { app };
