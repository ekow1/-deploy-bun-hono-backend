import { Hono } from "hono";
import { cors } from "hono/cors";
import { startServer } from "./config/serve.js";
import userRoutes from "./routes/user_routes.js";

const app = new Hono();

const PORT = process.env.PORT || 3000;

app.use("*", cors());


app.get("/", (c) => {
    return c.json({ message: "Server is running" });
});

app.route("/api/users", userRoutes);


startServer();

export default {
  port: PORT,
  fetch: app.fetch,
};


















