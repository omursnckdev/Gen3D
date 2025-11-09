import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import fetch from "node-fetch";

const MESHY_API_KEY = defineSecret("MESHY_API_KEY");

// ---- image-to-3D proxy ----
export const meshyImageTo3D = onRequest(
  { secrets: [MESHY_API_KEY] },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        return res.status(405).send("Use POST");
      }

      const response = await fetch("https://api.meshy.ai/openapi/v1/image-to-3d", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${MESHY_API_KEY.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(req.body),
      });

      const data = await response.json();
      res.status(response.status).json(data);
    } catch (err) {
      console.error("Meshy proxy error:", err);
      res.status(500).json({ error: err.message });
    }
  }
);

// ---- task status proxy ----
export const meshyGetTask = onRequest(
  { secrets: [MESHY_API_KEY] },
  async (req, res) => {
    try {
      const { taskId } = req.query;
      if (!taskId) return res.status(400).json({ error: "taskId required" });

      const response = await fetch(`https://api.meshy.ai/openapi/v1/image-to-3d/${taskId}`, {
        headers: {
          "Authorization": `Bearer ${MESHY_API_KEY.value()}`,
        },
      });

      const data = await response.json();
      res.status(response.status).json(data);
    } catch (err) {
      console.error("Get task error:", err);
      res.status(500).json({ error: err.message });
    }
  }
);
