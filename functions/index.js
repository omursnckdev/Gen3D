import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import fetch from "node-fetch";

const MESHY_API_KEY = defineSecret("MESHY_API_KEY");

// ---- text-to-3D proxy ----
export const meshyTextTo3D = onRequest(
  { secrets: [MESHY_API_KEY] },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        return res.status(405).send("Use POST");
      }

      const { mode, ...bodyWithoutMode } = req.body;

      // Determine the correct endpoint based on mode
      let endpoint;
      if (mode === "preview") {
        endpoint = "https://api.meshy.ai/v2/text-to-3d";
      } else if (mode === "refine") {
        endpoint = "https://api.meshy.ai/v2/text-to-3d";
      } else {
        return res.status(400).json({ error: "Invalid mode. Use 'preview' or 'refine'" });
      }

      // Forward request to Meshy API without the 'mode' parameter
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${MESHY_API_KEY.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(bodyWithoutMode),
      });

      const data = await response.json();
      res.status(response.status).json(data);
    } catch (err) {
      console.error("Meshy text-to-3D proxy error:", err);
      res.status(500).json({ error: err.message });
    }
  }
);

// ---- image-to-3D proxy ----
export const meshyImageTo3D = onRequest(
  { secrets: [MESHY_API_KEY] },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        return res.status(405).send("Use POST");
      }

      const response = await fetch("https://api.meshy.ai/v2/image-to-3d", {
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

// ---- task status proxy (supports both text-to-3D and image-to-3D) ----
export const meshyGetTask = onRequest(
  { secrets: [MESHY_API_KEY] },
  async (req, res) => {
    try {
      const { taskId } = req.query;
      if (!taskId) return res.status(400).json({ error: "taskId required" });

      // Try text-to-3D endpoint first, then fall back to image-to-3D
      // The Meshy API uses the same task ID format for both, so we try both endpoints
      let response = await fetch(`https://api.meshy.ai/v2/text-to-3d/${taskId}`, {
        headers: {
          "Authorization": `Bearer ${MESHY_API_KEY.value()}`,
        },
      });

      // If text-to-3D returns 404, try image-to-3D endpoint
      if (response.status === 404) {
        response = await fetch(`https://api.meshy.ai/v2/image-to-3d/${taskId}`, {
          headers: {
            "Authorization": `Bearer ${MESHY_API_KEY.value()}`,
          },
        });
      }

      const data = await response.json();
      res.status(response.status).json(data);
    } catch (err) {
      console.error("Get task error:", err);
      res.status(500).json({ error: err.message });
    }
  }
);
