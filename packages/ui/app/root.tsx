import { Pong } from "models";

import { json } from "@remix-run/node";
import {
  useLoaderData,
  Links,
  LiveReload,
  Meta,
  Scripts,
  ScrollRestoration,
} from "@remix-run/react";

import { config } from "./config";

export async function loader() {
  const response = await fetch(`${config.apiUrl}`, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
    },
  });

  return json(await response.json());
}

export default function App() {
  const data = useLoaderData<Pong>();

  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <Meta />
        <Links />
      </head>
      <body>
        <div
          style={{ textAlign: "center" }}
        >{`Ping (from version ${config.packageVersion}) > ${data.pong}`}</div>
        <ScrollRestoration />
        <Scripts />
        <LiveReload />
      </body>
    </html>
  );
}
